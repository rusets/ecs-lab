#############################################
# GitHub OIDC roles for CI/CD
# - Deploy role (least-privilege): enabled by default
# - Terraform role (broad perms): disabled by default to avoid bootstrap loops
#############################################

terraform {
  required_version = ">= 1.5"
}

# Toggle creation of roles (safe defaults for CI)
variable "manage_github_actions_deploy_role" {
  description = "Create least-privilege role for GitHub Actions deploy (ECR push + ECS update)"
  type        = bool
  default     = true
}

variable "manage_github_actions_terraform_role" {
  description = "Create broad-permission role for Terraform in GitHub Actions (Admin or wide perms). Keep false in CI."
  type        = bool
  default     = false
}

locals {
  aws_region = "us-east-1"

  # Your GitHub repository
  gh_repo = "rusets/docker-ecs-deployment"

  # Your resources (must match the rest of your Terraform)
  ecr_repo_name = "myapp"
  ecs_cluster   = "docker-ecs-deployment-cluster"
  ecs_service   = "docker-ecs-deployment-svc"
}

# Current account
data "aws_caller_identity" "current" {}

# Helper ARNs
locals {
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"

  ecr_repo_arn     = "arn:aws:ecr:${local.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.ecr_repo_name}"
  ecs_cluster_arn  = "arn:aws:ecs:${local.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${local.ecs_cluster}"
  ecs_service_arn  = "arn:aws:ecs:${local.aws_region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster}/${local.ecs_service}"
}

########################################################
# 1) Least-privilege Deploy Role (ECR push + ECS deploy)
########################################################
resource "aws_iam_role" "github_actions_ecs" {
  count = var.manage_github_actions_deploy_role ? 1 : 0
  name  = "github-actions-ecs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Federated = local.oidc_provider_arn },
        Action   = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            # only this repo can assume the role
            "token.actions.githubusercontent.com:sub" = "repo:${local.gh_repo}:*"
            # If you want to restrict to main branch only, use:
            # "token.actions.githubusercontent.com:sub" = "repo:${local.gh_repo}:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# Minimal permissions for deploy job:
# - ECR GetAuthorizationToken (resource "*": AWS requirement)
# - ECR push/pull scoped to your repository
# - ECS UpdateService/DescribeServices scoped to your service/cluster
resource "aws_iam_role_policy" "github_actions_ecs_least_priv" {
  count = var.manage_github_actions_deploy_role ? 1 : 0
  name  = "github-actions-ecs-ecr-minimal"
  role  = aws_iam_role.github_actions_ecs[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid": "EcrGetAuthToken",
        "Effect": "Allow",
        "Action": [ "ecr:GetAuthorizationToken" ],
        "Resource": "*"
      },
      {
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
      {
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

output "github_actions_ecs_role_arn" {
  value       = try(aws_iam_role.github_actions_ecs[0].arn, null)
  description = "OIDC least-privilege role for GitHub Actions deploy"
}

########################################################
# 2) (Optional) Terraform Role (broad permissions)
#    Enable only when you need to run terraform from Actions end-to-end.
########################################################
resource "aws_iam_role" "github_actions_terraform" {
  count = var.manage_github_actions_terraform_role ? 1 : 0
  name  = "github-actions-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Federated = local.oidc_provider_arn },
        Action   = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${local.gh_repo}:*"
          }
        }
      }
    ]
  })
}

# Easiest bootstrap: AdministratorAccess (you can later replace with least-privilege)
resource "aws_iam_role_policy_attachment" "github_actions_terraform_admin" {
  count      = var.manage_github_actions_terraform_role ? 1 : 0
  role       = aws_iam_role.github_actions_terraform[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_terraform_role_arn" {
  value       = try(aws_iam_role.github_actions_terraform[0].arn, null)
  description = "OIDC broad-permission role for Terraform (turn on via variable when needed)"
}