### Common

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "common_tags" {
  description = "A map of tags to add to resources"
  type        = map(string)
  default     = {}
}

## ERC
variable "repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
}

## Network

variable "vpc_cidr" {
  description = "CIDR block to use for the VPC"
  type        = string
  default     = ""
}

variable "private_subnets_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = []
}

variable "public_subnets_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "listener_certificate_arn" {
  description = "The ARN of certificate for TLS"
  type        = string
}

### aurora-postgresql
variable "vpc_id" {
  description = "The ID of the VPC where the Aurora cluster will be deployed"
  default     = ""
}

variable "cluster_identifier" {
  description = "Identifier for the Aurora cluster"
  default     = ""
}

variable "aurora_cluster_members" {
  description = "List of instances for aurora postgresql"
  type        = list(string)
  default     = []
}

variable "database_name" {
  description = "Name of the initial database to create"
  default     = ""
}

variable "aurora_cluster_master_username" {
  description = "Master username for Aurora db"
  type        = string
  default     = ""
}

variable "backup_retention_period" {
  description = "Number of days to retain backups (1-35)"
  default     = 7
}

variable "rds_logs_retention" {
  description = "Log retention in days"
  type        = number
  default     = "3"
}