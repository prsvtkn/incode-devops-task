## General
aws_region = "eu-central-1"
common_tags = {
  Created_by  = "terraform"
  Environment = "dev"
  Project     = "incode"
}

## VPC
vpc_cidr              = "10.120.0.0/16"
availability_zones    = ["eu-central-1a", "eu-central-1c"]
private_subnets_cidrs = ["10.120.1.0/24", "10.120.2.0/24"]
public_subnets_cidrs  = ["10.120.3.0/24", "10.120.4.0/24"]
listener_certificate_arn = "here_is_arn_of_already_created_and_validated_cerfiticate"

## ECR
image_tag_mutability = "IMMUTABLE"
repository_names     = [
  "dev/small-demo-app"
]

## ECS Fargate
fargate_logs_retention = "30"

## RDS-postgresql
cluster_identifier             = "incode-dev-aurora-psql"
database_name                  = "incode-dev-small-demo-app"
db_subnet_group_name           = "incode-dev-aurora-psql-subnet-group-name"
aurora_cluster_members         = ["incode-dev-wr1"]
aurora_cluster_master_username = "psqladmin"
rds_logs_retention             = "30"
