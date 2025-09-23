# Получаем доступные AZ в регионе
data "aws_availability_zones" "available" {}

# VPC с 2 public subnet (для ALB + ECS)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.2.0" # фиксируем актуальную версию модуля

  name = var.project_name
  cidr = var.vpc_cidr

  # Берём первые две AZ автоматически (например, us-east-1a, us-east-1b)
  azs            = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets = var.public_subnets

  # Для демо NAT не нужен
  enable_nat_gateway = false

  # Для ECS/ALB полезно иметь DNS поддержку в VPC
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Потоки VPC логов не включаем, чтобы не тащить CloudWatch Flow Logs и их варнинги
  # (по умолчанию и так выключено, поэтому просто ничего не указываем)
  # enable_flow_log = false
}

# Экспорты, если где-то нужны
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}