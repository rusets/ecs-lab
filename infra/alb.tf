# Application Load Balancer
resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id] # sg.tf already defines this SG
  subnets            = module.vpc.public_subnets

  idle_timeout = 60
  tags         = { Project = var.project_name }
}

# Target Group for ECS tasks (ip targets for Fargate)
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 15 # по умолчанию 30
    timeout             = 5
    healthy_threshold   = 2 # по умолчанию 5
    unhealthy_threshold = 2
  }
  tags = { Project = var.project_name }
}

# HTTP listener (80) → forward to TG
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
