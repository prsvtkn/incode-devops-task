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
