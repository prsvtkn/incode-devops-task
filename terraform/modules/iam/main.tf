data "aws_caller_identity" "main" {}

locals {
  account_id = data.aws_caller_identity.main.account_id
}

# to make github actions work 
resource "aws_iam_openid_connect_provider" "oidc_token_actions_githubusercontent_com" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

### GH Role
resource "aws_iam_role" "github_actions_role" {
  max_session_duration = "3600"
  name                 = "GitHubRole${upper(var.common_tags["Environment"])}"
  path                 = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:prsvtkn/incode-devops-task"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "gihub_actions" {
  name        = "IamGithubActionsPolicy${upper(var.common_tags["Environment"])}"
  description = "Policy for gihub_actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Policy to allow terraform to use dynamodb
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/${var.terraform_dynamodb_name}"
      },
      # Logs
      {
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = "*"
      },
      # IAM
      {
        Effect = "Allow"
        Action = [
          "iam:*"
        ]
        Resource = "*"
      },
      # Secrets Manager
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:*"
        ]
        Resource = "*"
      },
      # ECR
      {
        Effect : "Allow",
        Action : [
          "ecr:*"
        ],
        Resource : "*"
      },
      # EC2
      {
        Effect : "Allow",
        Action : [
          "ec2:*"
        ],
        Resource : "*"
      },
      # Application-autoscaling
      {
        Effect : "Allow",
        Action : [
          "application-autoscaling:*"
        ],
        Resource : "*"
      },
      # Elasticloadbalancing
      {
        Effect : "Allow",
        Action : [
          "elasticloadbalancing:*"
        ],
        Resource : "*"
      },
      # S3
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = "*"
      },
      # RDS
      {
        Effect = "Allow"
        Action = [
          "rds:*"
        ]
        Resource = "*"
      },
      # Events
      {
        Effect = "Allow"
        Action = [
          "events:*"
        ]
        Resource = "*"
      }
      # any other full policy to make gh role to create, update, modify or delete resources
      # {
      #   Effect : "Allow",
      #   Action : [
      #     "cloudhsm:*"
      #   ],
      #   Resource : "*"
      # }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "GitHubRole_gihub_actions" {
  policy_arn = aws_iam_policy.gihub_actions.arn
  role       = aws_iam_role.github_actions_role.name
}
