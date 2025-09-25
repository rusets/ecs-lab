# infra/variables.tf

variable "project_name" {
  type        = string
  default     = "docker-ecs-deployment"
  description = "Project prefix used for naming resources"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.10.0.0/16"
  description = "CIDR block for the VPC"
}

variable "public_subnets" {
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
  description = "Public subnet CIDRs"
}

variable "ecr_repo_name" {
  type        = string
  default     = "myapp"
  description = "ECR repository name for the application"
}

variable "desired_count" {
  type        = number
  default     = 1
  description = "Number of ECS service tasks to run"
}

variable "task_cpu" {
  type        = string
  default     = "256"
  description = "Fargate task CPU units (256 = 0.25 vCPU)"
}

variable "task_memory" {
  type        = string
  default     = "512"
  description = "Fargate task memory (in MiB)"
}

variable "app_port" {
  type        = number
  default     = 80
  description = "Port the application listens on"
}