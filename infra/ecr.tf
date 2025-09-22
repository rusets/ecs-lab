# ecr.tf — create/manage ECR repo in Terraform
resource "aws_ecr_repository" "this" {
  name                 = var.ecr_repo_name # например: "myapp"
  force_delete         = true              # чтобы destroy не падал, если остались образы
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # Необязательно, но ок:
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Project = var.project_name
    Name    = "${var.project_name}-ecr"
  }
}