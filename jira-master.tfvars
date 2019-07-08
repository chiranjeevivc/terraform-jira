#---------------------------------------------------------------
#Common Variables
#---------------------------------------------------------------

region = "us-east-1"
name="chiru-jira"

#---------------------------------------------------------------
# EFS Variables
#---------------------------------------------------------------

efs-name = "Chiru-Jira-EFS"
encrypted = true
kms_key_id = "kms_id"

efs-tags={
    "customer_name" = "Chiru-Jira-EFS"
    "environment"="chiru"
    "owner"="chiru"
  }

vpc_id = "vpc-id"

efs_subnet_ids = ["subnet-id", "subnet-id"]

#########
# EFS SG Ingress
#########
efs_rules_ingress={
    ingress_rules_0 = ["2049", "2049", "tcp", "Inbound access to jira", "10.0.0.0/16"]
}

#########
# EFS SG Egress
#########

efs_rules_egress={
    egress_rules_0  = ["0", "0", "-1", "Outbound access to all", "0.0.0.0/0"]
}

jira_home = "/mnt/JIRA_HOME"
#-------------------------------------------------------------------
# jira Security Group
#-------------------------------------------------------------------

sg_description  = "Security Group for jira Master"

#########
# Ingress
#########
rules_ingress={
    ingress_rules_0 = ["8080", "8080", "tcp", "Inbound access to jira HTTP", "0.0.0.0/0"]
    ingress_rules_1 = ["22", "22", "tcp", "Inbound access to jira SSH", "0.0.0.0/0"]
    ingress_rules_2 = ["2049", "2049", "tcp", "Inbound access to NFS", "0.0.0.0/0"]
    ingress_rules_3 = ["80", "80", "tcp", "Inbound access to jira HTTP", "0.0.0.0/0"]
}

#########
# Egress
#########

rules_egress={
    egress_rules_0  = ["0", "0", "-1", "Outbound access to all", "0.0.0.0/0"]
    
}

tags={
    "customer_name" = "jira-Master"
    "environment"="chiru"
    "owner"="chiru"
  }

#-------------------------------------------------------------------
# jira LC And ASG
#-------------------------------------------------------------------
# jira-Master-2019-04-04T22-58-58Z
image_id = "ami-createdami"  

instance_type = "t2.medium"
key_name = "keyname"
asg_subnet_ids = ["subnet-id", "subnet-id"]
health_check_type = "ELB"
min_size = "1"
max_size = "1"
desired_capacity = "1"
enabled_metrics = []

asg_tags = [
     {
       key                 = "environment"
       value               = "chiru"
       propagate_at_launch = true
     },
     {
       key                 = "owner"
       value               = "chiru"
       propagate_at_launch = true
     },
   ]

#-------------------------------------------------------------------
# jira ALB
#-------------------------------------------------------------------

load_balancer_type = "application"
security_groups= ["sg-groupdid"]
create_nlb= false
create_alb= true
rules_alb={
    rules_alb_0 = ["8080", "HTTP", "vpc-id", "Chiru-Jira-TG","/status","5", "2", "30", "5","200-308"]
}

rules_listener_alb={
    rules_listener_alb_0 = ["80", "HTTP"]
}

#-------------------------------------------------------------------
# jira RDS
#-------------------------------------------------------------------

identifier = "chiru-jira"
engine            = "postgres"
engine_version    = "9.6.3"
instance_class    = "db.t2.medium"
allocated_storage = 5
storage_encrypted = false

# kms_key_id        = "arm:aws:kms:<region>:<account id>:key/<kms key id>"

db_name = "dbname"

# NOTE: Do NOT use 'user' as the value for 'username' as it throws:
# "Error creating DB Instance: InvalidParameterValue: MasterUsername
# user cannot be used as it is a reserved word used by the engine"
db_username = "username"
db_password = "password"
port     = "5432"
db_vpc_security_group_ids = ["sg-groupid"]
maintenance_window = "Mon:00:00-Mon:03:00"
backup_window      = "03:00-06:00"

# disable backups to create DB faster
backup_retention_period = 0
db_tags = {
    Owner       = "Chiru-Jira"
    Environment = "dev"
  }
enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

# DB subnet group
db_subnet_ids = ["subnet-id", "subnet-id"]

# DB parameter group
family = "postgres9.6"
# DB option group
major_engine_version = "9.6"

# Snapshot name upon DB deletion
final_snapshot_identifier = "ChiruJira"

# Database Deletion Protection
deletion_protection = true