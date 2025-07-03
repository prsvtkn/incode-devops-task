data "aws_caller_identity" "main" {}

### Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "ecs_fargate" {
  name = "/aws/ecs/${var.common_tags["Project"]}/${var.common_tags["Environment"]}"

  retention_in_days = var.fargate_logs_retention
}

### ECS cluster
resource "aws_ecs_cluster" "fargate_cluster" {
  name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-fargate-cluster"

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.main.arn
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.common_tags, { Name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-cluster" })
}

# ecs_task_execution_role

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_exec" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_secret_access" {
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "IamECSTaskExecutionAccessSecretsPolicy${upper(var.common_tags["Environment"])}"
  description = "Policy for IamECSTaskExecutionAccessSecretsPolicy${upper(var.common_tags["Environment"])}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # access to secrets
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.main.account_id}:secret:${var.common_tags["Project"]}-${var.common_tags["Environment"]}-aurora-postgres-credentials-*"
        ]
      },
      # access for service connect logging
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      },
      # access for service discovery
      {
        Effect = "Allow"
        Action = [
          "servicediscovery:RegisterInstance",
          "servicediscovery:DeregisterInstance",
          "servicediscovery:DiscoverInstances",
          "servicediscovery:GetNamespace",
          "servicediscovery:GetService"
        ]
        Resource = "*"
      },
    ]
  })
}

# Moniroting example
resource "aws_sns_topic" "ecs_events" {
  name = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-ecs-events"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.ecs_events.arn
  name      = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-rds-event-sub"
  endpoint  = "sqs"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}-ecs-small-demo-app-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS Task CPU > 80% for 15 minutes"
  dimensions = {
    ClusterName = aws_ecs_cluster.fargate_cluster.name,
    # here is a list of tasks, I have to research how to put them here, 
    # because services and tasks are under ecspresso control
  }
  alarm_actions = [aws_sns_topic.ecs_events.arn]
}
