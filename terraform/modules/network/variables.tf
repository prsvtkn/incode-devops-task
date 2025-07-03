variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "A map of tags to add to resources"
  type        = map(string)
  default     = {}
}

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
