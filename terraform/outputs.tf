### ECR
output "repository_urls" {
  description = "The URL of the repository"
  value       = module.ecr.repository_urls
}

### ECS
output "ecs_task_execution_role" {
  description = "ARN of the created IAM role for ECS task execution"
  value       = module.iam.ecs_task_execution_role
}

### IAM
output "github_actions_role" {
  description = "ARN of the created IAM role for Github"
  value       = module.iam.github_actions_role
}

### Network
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.network.vpc_id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = module.network.private_subnet_id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = module.network.public_subnet_id
}

output "ecs_fargate_sg" {
  description = "Fargate security group"
  value       = module.network.ecs_fargate_sg
}

output "alb_sg" {
  description = "ALB security group"
  value       = module.network.alb_sg
}

output "alb_arn" {
  description = "The ARN of the Network Load Balancer."
  value       = module.network.alb_arn
}

output "alb_dns_name" {
  description = "The DNS name of the Network Load Balancer."
  value       = module.network.alb_dns_name
}

output "small_demo_app_tg" {
  description = "Small demo app Target group"
  value       = module.network.small_demo_app_tg
}
