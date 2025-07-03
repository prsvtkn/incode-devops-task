variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "A map of tags to add to resources"
  type        = map(string)
  default     = {}
}

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
