resource "aws_cloudwatch_log_group" "main" {
  name              = "/eks/${var.project_name}"
  retention_in_days = 7
  tags              = { Project = var.project_name }
}
