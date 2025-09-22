#############################################
# GitHub OIDC (reuse existing) + Least-Privilege Role
#############################################

locals {
  aws_region     = "us-east-1"

  gh_repo       = "rusets/docker-ecs-deployment"
  ecr_repo_name = "myapp"
  ecs_cluster   = "docker-ecs-deployment-cluster"
  ecs_service   = "docker-ecs-deployment-svc"
}

# Текущий аккаунт (для подстановки account_id)
data "aws_caller_identity" "current" {}

# ВАЖНО: НЕ читаем OIDC провайдера через data, сразу используем его ARN
# arn:aws:iam::<account_id>:oidc-provider/token.actions.githubusercontent.com

resource "aws_iam_role" "github_actions" {
  name = "github-actions-ecs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            # Разрешаем только этот репозиторий
            "token.actions.githubusercontent.com:sub" = "repo:${local.gh_repo}:*"
            # Чтобы ограничить только main-веткой, можно так:
            # "token.actions.githubusercontent.com:sub" = "repo:${local.gh_repo}:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# Удобные ARNs
locals {
  ecr_repo_arn    = "arn:aws:ecr:${local.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.ecr_repo_name}"
  ecs_cluster_arn = "arn:aws:ecs:${local.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${local.ecs_cluster}"
  ecs_service_arn = "arn:aws:ecs:${local.aws_region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster}/${local.ecs_service}"
}

# Минимальные права: ECR push/pull к конкретному репо + ECS Update/Describe для твоего сервиса
resource "aws_iam_role_policy" "github_actions_least_priv" {
  name = "github-actions-ecs-ecr-minimal"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { # токен для docker login к ECR — всегда Resource:"*"
        "Sid": "EcrGetAuthToken",
        "Effect": "Allow",
        "Action": [ "ecr:GetAuthorizationToken" ],
        "Resource": "*"
      },
      { # операции push/pull строго для твоего ECR репозитория
        "Sid": "EcrPushPullScoped",
        "Effect": "Allow",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],
        "Resource": local.ecr_repo_arn
      },
      { # форс-деплой и чтение статуса для конкретного сервиса/кластера
        "Sid": "EcsUpdateDescribeService",
        "Effect": "Allow",
        "Action": [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ],
        "Resource": [
          local.ecs_service_arn,
          local.ecs_cluster_arn
        ]
      }
    ]
  })
}