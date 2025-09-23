############################################
# ECS TaskDef + Service + ALB TG/Listener
# Порт приложения внутри контейнера: 3000
############################################

# === Параметры (убедись, что есть такие переменные)
# variable "project_name"   { type = string }
# variable "region"         { type = string }
# variable "desired_count"  { type = number }
# variable "task_cpu"       { type = string }
# variable "task_memory"    { type = string }
# variable "app_port"       { type = number }  # <- 3000
# variable "ecr_repo_name"  { type = string }

# === Кластер ECS (если уже создан в другом файле — убери этот блок)
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}

# === CloudWatch Logs для контейнера
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 14
  tags              = { Project = var.project_name }
}

# === ECR репозиторий (если уже создан в ecr.tf — убери этот блок)
resource "aws_ecr_repository" "this" {
  name         = var.ecr_repo_name
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Project = var.project_name }
}

# === IAM роли для Task (execution + task) — если есть в ecs-iam.tf, убери эти блоки
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# === Task Definition (Fargate) — ПОРТ 3000
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.this.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = var.app_port   # <- 3000
          hostPort      = var.app_port   # <- 3000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = { Project = var.project_name }
}

# === ALB (если уже создан — убери этот блок и оставь только TG/Listener)
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
  idle_timeout       = 60
  tags               = { Project = var.project_name }
}

# SG для ALB — вход 80 из мира
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from world"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Project = var.project_name }
}

# SG для сервиса — трафик только от ALB на порт 3000
resource "aws_security_group" "service" {
  name        = "${var.project_name}-svc-sg"
  description = "Service SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "From ALB"
    from_port       = var.app_port   # 3000
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Project = var.project_name }
}

# === Target Group на 3000 (IP targets for Fargate)
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = var.app_port            # <- 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    protocol            = "HTTP"
    path                = "/"           # поменяй на "/health", если есть такой endpoint
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Project = var.project_name }
}

# === Listener 80 -> TG:3000
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# === ECS Service (Fargate) с привязкой к ALB
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  propagate_tags  = "SERVICE"

  network_configuration {
    subnets         = module.vpc.public_subnets
    security_groups = [aws_security_group.service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = var.app_port   # 3000
  }

  lifecycle {
    ignore_changes = [task_definition] # чтобы простая перекатка не стопорилась
  }

  depends_on = [aws_lb_listener.http]
  tags       = { Project = var.project_name }
}