variable "project_name" {
  type        = string
  default     = "docker-ecs-deployment"
  description = "Project prefix"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "cluster_name" {
  type        = string
  default     = "docker-eks"
  description = "EKS cluster name"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.29"
  description = "EKS Kubernetes version"
}

variable "desired_size" {
  type        = number
  default     = 2
  description = "Node group desired size"
}

variable "min_size" {
  type        = number
  default     = 2
  description = "Node group min size"
}

variable "max_size" {
  type        = number
  default     = 3
  description = "Node group max size"
}

variable "instance_types" {
  type        = list(string)
  default     = ["t3.small"]
  description = "EC2 instance types for the node group"
}

variable "enable_cluster_logs" {
  type        = bool
  default     = true
  description = "Whether to enable EKS control plane logs"
}

# IRSA role ARN for External Secrets Operator (used in helm-eso.tf)
variable "eso_irsa_role_arn" {
  type        = string
  description = "IAM role ARN to annotate on the ESO service account (eks.amazonaws.com/role-arn)"
}