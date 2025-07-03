output "cluster_id" {
  description = "The ID of the created ECS Cluster."
  value       = aws_ecs_cluster.fargate_cluster.id
}

output "aws_cloudwatch_log_group" {
  description = "The name of cloudwatch ecs fargate log group."
  value       = aws_cloudwatch_log_group.ecs_fargate.name
}
