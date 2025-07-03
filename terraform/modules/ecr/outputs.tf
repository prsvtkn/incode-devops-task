output "repository_urls" {
  description = "The URL of the repository"
  value       = aws_ecr_repository.repos[*].repository_url
}
