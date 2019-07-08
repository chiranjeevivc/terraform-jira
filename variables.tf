variable "region" {
  description = "The AWS region"
  default     = ""
}

variable "name" {
  description = "Name for jira Master" 
  type        = "string"
  default     = "jira-master"
}

#------------------------------------
# RDS Variables
#------------------------------------

variable "identifier" {
  description = "The name of the RDS instance, if omitted, Terraform will assign a random, unique identifier"
  type        = "string"
}

variable "engine" {
  description = "The database engine to use"
  type        = "string"
}

variable "engine_version" {
  description = "The engine version to use"
  type        = "string"
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = "string"
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = "string"
}

variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD). The default is 'io1' if iops is specified, 'standard' if not. Note that this behaviour is different from the AWS web console, where the default is 'gp2'."
  type        = "string"
  default     = "gp2"
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  default     = false
}

variable "db_name" {
  description = "The DB name to create. If omitted, no database is created initially"
  type        = "string"
  default     = ""
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = "string"
}

variable "db_password" {
  description = "Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file"
  type        = "string"
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = "string"
}

variable "db_vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = "list"
  default     = []
}

variable "maintenance_window" {
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00'"
  type        = "string"
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = "string"
  default     = 1
}

variable "backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance_window"
  type        = "string"
}

variable "db_tags" {
  description = "A mapping of tags to assign to all resources"
  type        = "map"
  default     = {}
}

# DB subnet group
variable "db_subnet_ids" {
  type        = "list"
  description = "A list of VPC subnet IDs"
  default     = []
}

# DB parameter group
variable "family" {
  description = "The family of the DB parameter group"
  type        = "string"
  default     = ""
}

variable "major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
  type        = "string"
  default     = ""
}

variable "deletion_protection" {
  description = "The database can't be deleted when this value is set to true."
  type        = "string"
  default     = false
}

variable "final_snapshot_identifier" {
  description = "The name of your final DB snapshot when this DB instance is deleted."
  default     = false
}

#------------------------------------
# EFS Variables
#------------------------------------

variable "performance_mode" {
  description = "The file system performance mode. Can be either generalPurpose or maxIO"
  type        = "string"
  default     = "generalPurpose"
}

variable "encrypted" {
  description = "If true, the disk will be encrypted"
  type        = "string"
  default     = "false"
}

variable "kms_key_id" {
  description = "ARN for the KMS encryption key. When specifying kms_key_id, encrypted needs to be set to true"
  type        = "string"
  default     = ""
}

variable "efs-tags" {
  description = "A map of additional tags"
  type        = "map"
  default     = {}
}


variable "efs_subnet_ids" {
  description = "AWS subnet IDs"
  type        = "list"
}

variable "vpc_id" {
  description = "AWS VPC ID"
  type        = "string"
}

variable "efs-sg_description" {
  description = "Security Group for EFS for jira"
  type        = "string"
  default     = "Security Group for EFS for jira"
}


##########
# Ingress
##########
variable "efs_rules_ingress" {
  description = "Map of known security group rules (define as 'name' = ['from port', 'to port', 'protocol', 'description'])"
  type        = "map"
}


##########
# Egress
##########
variable "efs_rules_egress" {
  description = "Map of known security group rules (define as 'name' = ['from port', 'to port', 'protocol', 'description'])"
  type        = "map"
}

variable "jira_home" {
  description = "The folder where jira is installed"
  type="string" 
}

#-------------------------------------------------------------------
# jira Security Group
#-------------------------------------------------------------------

variable "sg_description" {
  description = "Description of security group for jira Master"
  default     = "Security Group managed by Terraform for jira Master"
}

##########
# Ingress
##########
variable "rules_ingress" {
  description = "Map of known security group rules (define as 'name' = ['from port', 'to port', 'protocol', 'description'])"
  type        = "map"
}


##########
# Egress
##########
variable "rules_egress" {
  description = "Map of known security group rules (define as 'name' = ['from port', 'to port', 'protocol', 'description'])"
  type        = "map"
}

variable "tags" {
  description = "A map of additional tags"
  type        = "map"
  default     = {}
}

#-------------------------------------------------------------------
# jira LC And ASG
#-------------------------------------------------------------------

variable "image_id" {
  description = "The EC2 image ID to launch"
}

variable "instance_type" {
  description = "The type of instance to start"
}

variable "key_name" {
  description = "The key name to use for the instance"
  default     = ""
}

variable "asg_subnet_ids" {
  description = "List of VPC Subnet IDs to launch in"
  type        = "list"
  default     = []
}
variable "health_check_type" {
  description = "Controls how health checking is done. Values are - EC2 and ELB"
}

variable "min_size" {
  description = "The minimum size of the auto scale group"
}

variable "max_size" {
  description = "The maximum size of the auto scale group"
}

variable "desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group"
}

variable "enabled_metrics" {
  type = "list"
}

variable "asg_tags" {
  type = "list"
}
#-------------------------------------------------------------------
# jira ALB
#-------------------------------------------------------------------

variable "load_balancer_type" {
  description = "The type of the ELB"
  default="application"
}

variable "security_groups" {
  default = []
}

variable "create_nlb" {
  default = true
}

variable "create_alb" {
  default = false
}

variable "rules_alb" {
  description = "Map of alb rules (define as 'name' = ['port', 'protocol', 'vpc_id', 'name'])"
  type        = "map"
  default = {}
}


// ## Listener Rules for Network Load balancer

variable "rules_listener_alb" {
  description = "Map of alb listener rules (define as 'name' = ['port', 'protocol', 'ssl_policy', 'certificate_arn'])"
  type        = "map"
  default = {}
}


