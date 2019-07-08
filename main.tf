provider "aws" {
  region = "${var.region}"
}

# Declare the data source
data "aws_availability_zones" "available" {}


######
# Security Group for EFS
######

module "jira_efs_sg" {

  source = "git::https://github.com/chiranjeevivc/chiru-base-tf-modules.git//networking0/security-groups/"

    create        = true
    name          = "${var.name}-efs-sg"
    description   = "${var.efs-sg_description}"
    vpc_id        = "${var.vpc_id}"
    tags          = "${var.efs-tags}"
    rules_ingress = "${var.efs_rules_ingress}"
    rules_egress  = "${var.efs_rules_egress}"

}

######
# EFS
######

module "jira_efs" {

  source = "git::https://github.com/chiranjeevivc/chiru-base-tf-modules.git//storage/efs/"
  
  name             = "${var.name}-efs"
  performance_mode = "${var.performance_mode}"
  encrypted        = "${var.encrypted}"
  kms_key_id       = "${var.kms_key_id}"
  tags             = "${var.efs-tags}"
  security_groups  = ["${module.jira_efs_sg.security_group_id}"]
  subnets          = "${var.efs_subnet_ids}" 
  vpc_id           = "${var.vpc_id}"

}


######
# User Data to mount EFS
######

data "template_file" "jira_user_data" {
 template = "${file("mountEFS.tpl")}"

 vars {
    EFS_dns_name = "${module.jira_efs.dns_name}"
    jira_HOME = "${var.jira_home}"
  }
}

## SECURITY GROUP
module "jira_sg" {

  source = "git::https://github.com/chiranjeevivc/chiru-base-tf-modules.git//networking0/security-groups/"

    create        = true
    name          = "${var.name}-sg"
    description   = "${var.sg_description}"
    vpc_id        = "${var.vpc_id}"
    tags          = "${var.tags}"
    rules_ingress = "${var.rules_ingress}"
    rules_egress  = "${var.rules_egress}"

}


######
# RDS for JIRA
######

module "jira_db" {
  source = "git::https://github.com/chiranjeevivc/chiru-base-tf-modules.git//storage/rds/"

  identifier = "${var.identifier}"

  engine            = "${var.engine}"
  engine_version    = "${var.engine_version}"
  instance_class    = "${var.instance_class}"
  allocated_storage = "${var.allocated_storage}"
  storage_encrypted = "${var.storage_encrypted}"

  # kms_key_id        = "arm:aws:kms:<region>:<account id>:key/<kms key id>"
  name = "${var.db_name}"

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  username = "${var.db_username}"

  password = "${var.db_password}"
  port     = "${var.port}"

  vpc_security_group_ids = "${var.db_vpc_security_group_ids}"

  maintenance_window = "${var.maintenance_window}"

  backup_window      = "${var.backup_window}"


  # disable backups to create DB faster
  backup_retention_period = "${var.backup_retention_period}"


  tags = "${var.db_tags}"

  # DB subnet group
  subnet_ids = "${var.db_subnet_ids}"


  # DB parameter group
  family = "${var.family}"

  # DB option group
  major_engine_version = "${var.major_engine_version}"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "${var.final_snapshot_identifier}"

  # Database Deletion Protection
  deletion_protection = "${var.deletion_protection}"
}



######
# Launch configuration and autoscaling group
######
module "jira_asg" {
  source = "git::https://github.com/chiranjeevivc/chiru-base-tf-modules.git//compute/asg/"
  
  lc_name                      = "${var.name}-asg-lc"
  image_id                     = "${var.image_id}"
  instance_type                = "${var.instance_type}"
  security_groups              = ["${module.jira_sg.this_security_group_id}"]
  key_name                     = "${var.key_name}"
  user_data                    = "${data.template_file.jira_user_data.rendered}"
  create_lc                    = true
  create_asg                   = true
  # Auto scaling group
  name                          = "${var.name}-asg"
  vpc_zone_identifier           = "${var.asg_subnet_ids}"
  health_check_type             = "${var.health_check_type}"
  min_size                      = "${var.min_size}"
  max_size                      = "${var.max_size}"
  desired_capacity              = "${var.desired_capacity}"
  placement_tenancy             = ""
  termination_policies          = []
  enabled_metrics               = ["${var.enabled_metrics}"]
  target_group_arns             = ["${module.jira_alb.target_group_arns_alb}"]
  tags                          = "${var.asg_tags}"

}


module "jira_alb" {
  source= "git::https://github.com/chiranjeevivc/chiru-base-tf-modules.git//compute/lb/"
  
  name = "${var.name}-alb"
  load_balancer_type = "${var.load_balancer_type}"
  subnets         = ["${var.asg_subnet_ids}"]
  security_groups = "${var.security_groups}"
  internal        = true
  vpc_id= "${var.vpc_id}"
  create_nlb="${var.create_nlb}"
  create_alb="${var.create_alb}"
  rules_alb="${var.rules_alb}"
  rules_listener_alb="${var.rules_listener_alb}"
  tags =  "${var.tags}"
}