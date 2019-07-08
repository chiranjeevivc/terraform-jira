# JIRA Installation

  This will use the Terraform Module found in Github Repository [chiru-base-tf-modules](https://github.com/chiranjeevivc/chiru-base-tf-moduless.git").

Following components are installed:  
  1. Security Group for Elastic File System (EFS)  
  2. Elastic File System (EFS)  
  3. Security Group for JIRA Server  
  4. User Data Script component to bootstrap JIRA  
  5. Autoscaling Group With Launch Configuration  
  6. Application Load Balancer  
  7. RDS(Postgres) Instance for JIRA
  
JIRA runs with an autoscaling configuration of min=1, max=1 with the home directory mounted on EFS    

## Usage  

### Security Group for Elastic File System (EFS)
```
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
```
#### Variables

| Variables           | Default Value   | Description  |
| :-------------      |:-------------   | :-----|
| create                |                 | Whether to create a Security Group (true/false) |
| name     |                 |  Name of the Security Group  |
| description             |         |   A Description of the Security Group  |
| vpc_id                |      |   VPC where the Security Group is to be created  |
| tags              |                 | Tags to be associated with Security Group   |
| rules_ingress          |                 | Ingress CIDRs with defined ports   |
| rules_egress                |                 |  Egress CIDRs with defined ports   |

### Elastic File System (EFS)
```
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
```
#### Variables

| Variables           | Default Value   | Description  |
| :-------------      |:-------------   | :-----|
| name     |                 |  Name of the Elastic File System  |
| performance_mode             |   generalPurpose      |   Either generalPurpose or maxIO  |
| encrypted                |   false   |   Whether EFS is to encrypted  |
| kms_key_id                |     |   KMS Key to be used for encryption if encryption is true |
| tags              |                 | Tags to be associated with EFS   |
| security_groups          |                 | Security Group to be associated to EFS. EFS requires 2049 port to be open for connections   |
| subnets                |                 |  Subnets where EFS is to be installed   |
| vpc_id                |                 |  VPC where the EFS is to be created   |

### Security Group for JIRA Server

```
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
```
#### Variables

| Variables           | Default Value   | Description  |
| :-------------      |:-------------   | :-----|
| create                |                 | Whether to create a Security Group (true/false) |
| name     |                 |  Name of the Security Group  |
| description             |         |   A Description of the Security Group  |
| vpc_id                |      |   VPC where the Security Group is to be created  |
| tags              |                 | Tags to be associated with Security Group   |
| rules_ingress          |                 | Ingress CIDRs with defined ports   |
| rules_egress                |                 |  Egress CIDRs with defined ports   |


### User Data Script component to bootstrap JIRA

The script performs the following actions
    1. Stop jira
    2. move mnt/confluence to /tmp/jira
    3. Mount EFS on mnt/jira_HOME
    5. IF EFS already has data, then skip
    6. Else Move /tmp/confluence to /mnt/confluence
    7. Delete /tmp/jira folder
    8. Start jira

```
data "template_file" "jira_user_data" {
 template = "${file("mountEFS.tpl")}"

 vars {
    EFS_dns_name = "${module.jira_efs.dns_name}"
    jira_HOME = "${var.jira_home}"
  }
}
```

#### Variables

| Variables           | Default Value   | Description  |
| :-------------      |:-------------   | :-----|
| EFS_dns_name                |                 | DNS Name of the EFS created earlier |
| jira_HOME     |                 |  Mount path where EFS will be mounted   |


### Autoscaling Group With Launch Configuration

```
module "jira_asg" {
  source = "git::https://github.com/chiranjeevivc/chiru-base-tf-modules.git//compute/asg/"
  
  lc_name                      = "${var.name}-asg-lc"
  image_id                     = "${var.image_id}"
  instance_type                = "${var.instance_type}"
  security_groups              = ["${module.jira_sg.this_security_group_id}"]
  key_name                     = "${var.key_name}"
  user_data                    = "${data.template_file.jira_user_data.rendered}"
  iam_instance_profile        = "${aws_iam_instance_profile.jira_instance_profile.name}"
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
```

#### Variables

| Variables           | Default Value   | Description  |
| :-------------      |:-------------   | :-----|
| lc_name                |                 | Launch Configuration Name |
| image_id     |                 |  AMI (Image) ID to be used by the launch configuration    |
| instance_type     |                 |  Type of instance (m5.large)   |
| security_groups     |                 |  Security Group to be used by the EC2 created by ASG   |
| iam_instance_profile     |                 |  Instance profile to be attached to the EC2 created by ASG  |
| create_lc     |                 |  true   |
| create_asg     |                 |  true   |
| name     |                 |  Name of the ASG   |
| vpc_zone_identifier     |                 |  Availability Zones defined by Subnets   |
| health_check_type     |                 |  ELB   |
| min_size     |                 |  1 as we need only one instance |
| max_size     |                 |  1 as we need only one instance |
| desired_capacity     |                 |  1 as we need only one instance   |
| placement_tenancy     |                 |  ""   |
| termination_policies     |                 |  ""   |
| enabled_metrics     |                 |  ""   |
| target_group_arns     |                 |  ""   |
| tags     |                 |  Tags for ASG, LC and EC2 created   |

### Application Load Balancer

```
module "jira_alb" {
  source= "git::https://github.com/chiranjeevivc/chiru-base-tf-modules.git//compute/lb/"
  
  name = "${var.name}-alb"
  load_balancer_type = "${var.load_balancer_type}"
  subnets         = ["${var.asg_subnet_ids}"]
  security_groups = ["${module.jira_sg.this_security_group_id}"]
  internal        = true
  vpc_id= "${var.vpc_id}"
  create_nlb="${var.create_nlb}"
  create_alb="${var.create_alb}"
  rules_alb="${var.rules_alb}"
  rules_listener_alb="${var.rules_listener_alb}"
  tags =  "${var.tags}"
}
```

#### Variables

| Variables           | Default Value   | Description  |
| :-------------      |:-------------   | :-----|
| name                |                 | Name of the Load Balancer |
| load_balancer_type     |                 |  Application. Posible options are Application/Network.    |
| subnets     |                 |   Subnets where the load balance target groups are created   |
| security_groups     |                 |  Security Group for the Load Balancer   |
| internal     |          internal       |  internal   |
| vpc_id     |                 |  VPC where the Load Balancer Target Groups are configured   |
| create_nlb     |                 |  false as this creates an application load balancer   |
| create_alb     |                 |  true as this creates an application load balancer   |
| rules_alb     |                 |  Ports and health check configuration for the target group   |
| rules_listener_alb     |                 |  ports where the load balancer listens on   |
| tags     |                 |  Tags for the load balancer and target groups    |


### RDS

```hcl
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
```

#### Variables

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allocated\_storage | The allocated storage in gigabytes | string | n/a | yes |
| allow\_major\_version\_upgrade | Indicates that major version upgrades are allowed. Changing this parameter does not result in an outage and the change is asynchronously applied as soon as possible | string | `"false"` | no |
| apply\_immediately | Specifies whether any database modifications are applied immediately, or during the next maintenance window | string | `"false"` | no |
| auto\_minor\_version\_upgrade | Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window | string | `"true"` | no |
| availability\_zone | The Availability Zone of the RDS instance | string | `""` | no |
| backup\_retention\_period | The days to retain backups for | string | `"1"` | no |
| backup\_window | The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance_window | string | n/a | yes |
| character\_set\_name | (Optional) The character set name to use for DB encoding in Oracle instances. This can't be changed. See Oracle Character Sets Supported in Amazon RDS for more information | string | `""` | no |
| copy\_tags\_to\_snapshot | On delete, copy all Instance tags to the final snapshot (if final_snapshot_identifier is specified) | string | `"false"` | no |
| create\_db\_instance | Whether to create a database instance | string | `"true"` | no |
| create\_db\_option\_group | Whether to create a database option group | string | `"true"` | no |
| create\_db\_parameter\_group | Whether to create a database parameter group | string | `"true"` | no |
| create\_db\_subnet\_group | Whether to create a database subnet group | string | `"true"` | no |
| create\_monitoring\_role | Create IAM role with a defined name that permits RDS to send enhanced monitoring metrics to CloudWatch Logs. | string | `"false"` | no |
| db\_subnet\_group\_name | Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC | string | `""` | no |
| deletion\_protection | The database can't be deleted when this value is set to true. | string | `"false"` | no |
| enabled\_cloudwatch\_logs\_exports | List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine): alert, audit, error, general, listener, slowquery, trace, postgresql (PostgreSQL), upgrade (PostgreSQL). | list | `<list>` | no |
| engine | The database engine to use | string | n/a | yes |
| engine\_version | The engine version to use | string | n/a | yes |
| family | The family of the DB parameter group | string | `""` | no |
| final\_snapshot\_identifier | The name of your final DB snapshot when this DB instance is deleted. | string | `"false"` | no |
| iam\_database\_authentication\_enabled | Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled | string | `"false"` | no |
| identifier | The name of the RDS instance, if omitted, Terraform will assign a random, unique identifier | string | n/a | yes |
| instance\_class | The instance type of the RDS instance | string | n/a | yes |
| iops | The amount of provisioned IOPS. Setting this implies a storage_type of 'io1' | string | `"0"` | no |
| kms\_key\_id | The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN. If storage_encrypted is set to true and kms_key_id is not specified the default KMS key created in your account will be used | string | `""` | no |
| license\_model | License model information for this DB instance. Optional, but required for some DB engines, i.e. Oracle SE1 | string | `""` | no |
| maintenance\_window | The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00' | string | n/a | yes |
| major\_engine\_version | Specifies the major version of the engine that this option group should be associated with | string | `""` | no |
| monitoring\_interval | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60. | string | `"0"` | no |
| monitoring\_role\_arn | The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs. Must be specified if monitoring_interval is non-zero. | string | `""` | no |
| monitoring\_role\_name | Name of the IAM role which will be created when create_monitoring_role is enabled. | string | `"rds-monitoring-role"` | no |
| multi\_az | Specifies if the RDS instance is multi-AZ | string | `"false"` | no |
| name | The DB name to create. If omitted, no database is created initially | string | `""` | no |
| option\_group\_description | The description of the option group | string | `""` | no |
| option\_group\_name | Name of the DB option group to associate. Setting this automatically disables option_group creation | string | `""` | no |
| options | A list of Options to apply. | list | `<list>` | no |
| parameter\_group\_description | Description of the DB parameter group to create | string | `""` | no |
| parameter\_group\_name | Name of the DB parameter group to associate or create | string | `""` | no |
| parameters | A list of DB parameters (map) to apply | list | `<list>` | no |
| password | Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file | string | n/a | yes |
| port | The port on which the DB accepts connections | string | n/a | yes |
| publicly\_accessible | Bool to control if instance is publicly accessible | string | `"false"` | no |
| replicate\_source\_db | Specifies that this resource is a Replicate database, and to use this value as the source database. This correlates to the identifier of another Amazon RDS Database to replicate. | string | `""` | no |
| skip\_final\_snapshot | Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted, using the value from final_snapshot_identifier | string | `"true"` | no |
| snapshot\_identifier | Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05. | string | `""` | no |
| storage\_encrypted | Specifies whether the DB instance is encrypted | string | `"false"` | no |
| storage\_type | One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD). The default is 'io1' if iops is specified, 'standard' if not. Note that this behaviour is different from the AWS web console, where the default is 'gp2'. | string | `"gp2"` | no |
| subnet\_ids | A list of VPC subnet IDs | list | `<list>` | no |
| tags | A mapping of tags to assign to all resources | map | `<map>` | no |
| use\_parameter\_group\_name\_prefix | Whether to use the parameter group name prefix or not | string | `"true"` | no |
| username | Username for the master DB user | string | n/a | yes |
| vpc\_security\_group\_ids | List of VPC security groups to associate | list | `<list>` | no |


## Commands to run script

To initialize a working directory containing Terraform configuration files. This will also initialize the backend configuration in config.tf for storing tfstate file in S3.
```
terraform init 
```
To see the number of resources getting created
```
terraform plan -var-file=jira-master.tfvars .
```
To apply terraform script. It will again show you the details of resources terraform script will create. type 'Yes' to confirm creating of resources.
```
terraform apply -var-file=jira-master.tfvars .
```

To destroy terraform script.
```
terraform apply -var-file=jira-master.tfvars .
```
  
