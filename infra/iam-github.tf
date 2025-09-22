#############################################
# GitHub OIDC (reuse existing) + Least-Privilege Role
#############################################

locals {
  aws_account_id = "097635932419"
  aws_region     = "us-east-1"

  gh_repo       = "rusets/docker-ecs-deployment"
  ecr_repo_name = "myapp"
  ecs_cluster   = "docker-ecs-deployment-cluster"
  ecs_service   = "docker-ecs-deployment-svc"
}

# Account ID (used to build the OIDC provider ARN)
data "aws_caller_identity" "current" {}

# REUSE EXISTING GitHub OIDC provider (do NOT create a new one)
# ARN format: arn:aws:iam::<account_id>:oidc-provider/token.actions.githubusercontent.com
data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# IAM Role that GitHub Actions (OIDC) can assume
resource "aws_iam_role" "github_actions" {
  name = "github-actions-ecs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            # Allow only your repo
            "token.actions.githubusercontent.com:sub" = "repo:${local.gh_repo}:*"
            # To restrict to main branch only, use this instead:
            # "token.actions.githubusercontent.com:sub" = "repo:${local.gh_repo}:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# Helpful ARNs
locals {
  ecr_repo_arn    = "arn:aws:ecr:${local.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.ecr_repo_name}"
  ecs_cluster_arn = "arn:aws:ecs:${local.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${local.ecs_cluster}"
  ecs_service_arn = "arn:aws:ecs:${local.aws_region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster}/${local.ecs_service}"
}

# Least-privilege inline policy: ECR (scoped), ECS (scoped)
resource "aws_iam_role_policy" "github_actions_least_priv" {
  name = "github-actions-ecs-ecr-minimal"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "EcrGetAuthToken",
        "Effect" : "Allow",
        "Action" : ["ecr:GetAuthorizationToken"],
        "Resource" : "*"
      },
      {
        "Sid" : "EcrPushPullScoped",
        "Effect" : "Allow",
        "Action" : [
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
        "Resource" : local.ecr_repo_arn
      },
      {
        "Sid" : "EcsUpdateDescribeService",
        "Effect" : "Allow",
        "Action" : [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ],
        "Resource" : [
          local.ecs_service_arn,
          local.ecs_cluster_arn
        ]
      }
    ]
  })
}