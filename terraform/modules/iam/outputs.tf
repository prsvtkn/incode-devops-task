output "github_actions_role" {
  description = "ARN of the created IAM role for ECS task execution"
  value       = aws_iam_role.github_actions_role.arn
}
