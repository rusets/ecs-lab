# VPC module from terraform-aws-modules
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  # Availability Zones — берём две в выбранном регионе
  azs            = ["${var.region}a", "${var.region}b"]
  public_subnets = var.public_subnets

  # Для простоты: без NAT, только публичные подсети
  enable_nat_gateway      = false
  single_nat_gateway      = false
  map_public_ip_on_launch = true

  tags = {
    Project = var.project_name
  }
}