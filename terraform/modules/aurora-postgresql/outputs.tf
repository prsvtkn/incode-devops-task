output "aurora_kms_key_alias" {
  description = "The KMS key alias for Aurora encryption"
  value       = aws_kms_alias.aurora_kms_key_alias.name
}

output "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint"
  value       = aws_rds_cluster.aurora_postgres.endpoint
}

output "aurora_cluster_port" {
  description = "Aurora cluster port"
  value       = aws_rds_cluster.aurora_postgres.port
}

output "aurora_cluster_databse_name" {
  description = "Aurora cluster database name"
  value       = aws_rds_cluster.aurora_postgres.database_name
}

output "aurora_cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = aws_rds_cluster.aurora_postgres.reader_endpoint
}

output "aurora_security_group_id" {
  description = "The security group ID for the Aurora cluster"
  value       = aws_security_group.aurora_sg.id
}

