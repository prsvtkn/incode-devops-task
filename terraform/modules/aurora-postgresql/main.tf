data "aws_caller_identity" "main" {}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.common_tags["Project"]}-${var.common_tags["Environment"]}-vpc-main"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["${var.common_tags["Project"]}-${var.common_tags["Environment"]}-private-subnet-*"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

data "aws_security_group" "aurora_sh" {
  filter {
    name   = "tag:Name"
    values = ["${var.common_tags["Project"]}-${var.common_tags["Environment"]}-aurora-postgres-sg"]
  }
}

data "aws_lambda_function" "secrets_rotation" {
  function_name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-lambda-secrets-rotation"
}

data "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-aurora-postgres-credentials"
}

data "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

# let's imagine we have a lambda which can rotate this secret
resource "aws_secretsmanager_secret_rotation" "db_credentials_rotation" {
  secret_id           = data.aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = data.aws_lambda_function.secrets_rotation.arn

  rotation_rules {
    automatically_after_days = 90
  }
}

# KMS key
resource "aws_kms_key" "aurora_kms_key" {
  description             = "KMS key for encrypting Aurora PostgreSQL cluster"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "aurora_kms_key_alias" {
  name          = "alias/${var.common_tags["Project"]}-${var.common_tags["Environment"]}-aurora-postgres-kms-key"
  target_key_id = aws_kms_key.aurora_kms_key.id
}

resource "aws_kms_key_policy" "aurora_kms_key_policy" {
  key_id = aws_kms_key.aurora_kms_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "default"
    Statement = [
      {
        Sid    = "Give all permissions on key to root account"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.main.account_id}:root"
        }
        Action   = "kms:*"
        Resource = aws_kms_key.aurora_kms_key.arn
      },
      {
        Sid    = "Allow use the key"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.main.arn
        }
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey", "kms:GenerateDataKeyWithoutPlaintext"]
        Resource = aws_kms_key.aurora_kms_key.arn
      }
    ]
  })
}

# Subnet group
resource "aws_db_subnet_group" "aurora-subnet-group" {
  name       = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-aurora-subnet-group"
  subnet_ids = data.aws_subnets.private.ids

  tags = {
    Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-aurora-postgres-subnet-group"
  }
}

# DB Params
resource "aws_db_parameter_group" "aurora_pg_params" {
  name        = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-aurora-postgres-pg-params"
  family      = "aurora-postgresql16"
  description = "Aurora PostgreSQL standard parameter group"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  # any other param
  # parameter {
  #   name  = "foo"
  #   value = "bar"
  # }
}

# Cluster
resource "aws_rds_cluster" "aurora_postgres" {
  cluster_identifier        = var.cluster_identifier
  engine                    = "aurora-postgresql"
  engine_version            = "16.8"
  engine_mode               = "provisioned"
  cluster_members           = var.aurora_cluster_members
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-aurora-postgres-db-snapshot-final"
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 5
  }

  database_name   = var.database_name
  master_username = var.aurora_cluster_master_username
  master_password = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string)["password"]

  vpc_security_group_ids          = [data.aws_security_group.aurora_sg.id]
  db_subnet_group_name            = aws_db_subnet_group.aurora-subnet-group.name
  storage_encrypted               = true
  backup_retention_period         = 7
  apply_immediately               = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
  master_user_secret_kms_key_id   = aws_kms_key.aurora_kms_key.key_id

  lifecycle {
    ignore_changes = [
      password
    ]
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count               = length(var.aurora_cluster_members)
  identifier          = var.aurora_cluster_members[count.index]
  cluster_identifier  = aws_rds_cluster.aurora_postgres.id
  instance_class      = "db.serverless"
  engine              = "aurora-postgresql"
  engine_version      = "16.6"
  monitoring_interval = 10
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn

  depends_on = [aws_rds_cluster.aurora_postgres]
}

resource "aws_cloudwatch_log_group" "aurora_postgresql_log_group" {
  name              = "/aws/rds/cluster/${aws_rds_cluster.aurora_postgres.id}/logs"
  retention_in_days = var.rds_logs_retention
}

# Moniroting example, it's a huge topic

resource "aws_iam_role" "rds_monitoring_role" {
  name               = "IamRDSMonitoringRole${upper(var.common_tags["Environment"])}"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  ]
}

data "aws_iam_policy_document" "rds_monitoring_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}


resource "aws_sns_topic" "rds_sns" {
  name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-rds-events"
}

resource "aws_db_event_subscription" "rds_event_sub" {
  name        = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-rds-event-sub"
  sns_topic   = aws_sns_topic.rds_sns.arn
  source_type = "db-cluster"
  source_ids  = [aws_rds_cluster.aurora_postgres.id]
  event_categories = [
    "creation",
    "deletion",
    "failover",
    "failure",
    "maintenance",
    "notification",
  ]
}

resource "aws_cloudwatch_metric_alarm" "cpu_util" {
  alarm_name          = "CPU_Util-${element(split(",", join(",", aws_rds_cluster_instance.cluster_instances[*].id)), count.index)}"
  alarm_description   = "This metric monitors Aurora Instance CPU Utilization"
  metric_name         = "CPUUtilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  treat_missing_data  = "notBreaching"
  period              = "60"
  threshold           = "80"
  statistic           = "Maximum"
  unit                = "Percent"
  alarm_actions       = [aws_sns_topic.rds_sns.arn]
  namespace           = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = element(aws_rds_cluster_instance.cluster_instances[*].id, count.index)
  }
}

resource "aws_cloudwatch_metric_alarm" "free_local_storage" {
  alarm_name          = "Free_local_storage-${element(split(",", join(",", aws_rds_cluster_instance.cluster_instances[*].id)), count.index)}"
  alarm_description   = "This metric monitors Aurora Local Storage Utilization"
  metric_name         = "FreeLocalStorage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  treat_missing_data  = "notBreaching"
  period              = "60"
  threshold           = "5368709120"
  statistic           = "Average"
  unit                = "Bytes"
  alarm_actions       = [aws_sns_topic.rds_sns.arn]
  namespace           = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = element(aws_rds_cluster_instance.cluster_instances[*].id, count.index)
  }
}

# a proxy here to control db connections