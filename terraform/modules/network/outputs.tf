output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private_subnet[*].id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public_subnet[*].id
}

output "ecs_fargate_sg" {
  description = "Fargate security group"
  value       = aws_security_group.ecs_fargate_sg.id
}

output "alb_sg" {
  description = "ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer."
  value       = aws_lb.alb.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.alb.dns_name
}

output "small_demo_app_tg" {
  description = "The ARN of the target group for the Load Balancer."
  value       = aws_lb_target_group.small_demo_app_tg.arn
}

