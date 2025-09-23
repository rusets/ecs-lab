# ECS / Fargate variables (do NOT duplicate these in other files)

# Port your container listens on (our Nginx inside the image listens on 80)
variable "app_port" {
  type        = number
  default     = 3000
  description = "Container listening port"
}

# How many tasks to run in the ECS service
variable "desired_count" {
  type        = number
  default     = 1
  description = "Number of ECS tasks to run"
}

# IMPORTANT for Fargate: cpu/memory must be STRINGS and be a compatible pair.
# Examples of valid pairs:
#   CPU: 256  -> Memory: 512, 1024, 2048
#   CPU: 512  -> Memory: 1024, 2048, 3072, 4096
#   CPU: 1024 -> Memory: 2048–8192 (step 1024)
#   CPU: 2048 -> Memory: 4096–16384 (step 1024)
#   CPU: 4096 -> Memory: 8192–30720 (step 1024)

variable "task_cpu" {
  type        = string
  default     = "256"
  description = "Fargate task CPU units (string)"
}

variable "task_memory" {
  type        = string
  default     = "512"
  description = "Fargate task memory in MiB (string)"
}
