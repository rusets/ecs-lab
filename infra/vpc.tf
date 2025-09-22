# VPC with 2 public subnets (sufficient for ECS + ALB demo)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = var.project_name
  cidr = var.vpc_cidr

  # Availability Zones (например, us-east-1a и us-east-1b)
  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = var.public_subnets
  private_subnets = []

  enable_nat_gateway = false

  # ❌ Отключаем Flow Logs, чтобы не было warning и лишних ресурсов
  enable_flow_log = false

  tags = {
    Project = var.project_name
  }
}