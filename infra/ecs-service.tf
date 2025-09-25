############################################
# ECS Task Definition + Service (Fargate)
# Контейнер слушает var.app_port (рекомендуется 80)
############################################

# variables (должны быть объявлены где-то у тебя)
# variable "project_name"  { type = string }
# variable "region"        { type = string }
# variable "desired_count" { type = number }
# variable "task_cpu"      { type = string }
# variable "task_memory"   { type = string }
# variable "app_port"      { type = number } # рекомендую default = 80

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
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      # если нужно — можно добавить переменные окружения:
      # environment = [
      #   { name = "PORT", value = tostring(var.app_port) }
      # ]
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = { Project = var.project_name }
}

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  propagate_tags  = "SERVICE"

  # Рекомендуется private subnets + NAT; если пока нет NAT — оставляй public+assign_public_ip=true
  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = var.app_port
  }

  # Тюнинг деплоя и прогрева
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    # чтобы обновление task definition из CI (aws ecs update-service) не вызывало лишние дифы
    ignore_changes = [task_definition]
  }

  depends_on = [
    aws_lb_target_group.app
  ]

  tags = { Project = var.project_name }
}