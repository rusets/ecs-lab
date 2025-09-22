#############################################
# ECS Service: SG + Task Definition + Service
#############################################

# Security Group for ECS tasks (allow traffic only from ALB)
resource "aws_security_group" "service" {
  name_prefix = "${var.project_name}-svc-"
  description = "Allow app traffic from ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "From ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # ALB SG is defined in sg.tf
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Project = var.project_name }
}

# Task Definition (Fargate)
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu    # string, e.g. "256"
  memory                   = var.task_memory # string, e.g. "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.this.repository_url}:latest"
      essential = true
      portMappings = [{
        containerPort = var.app_port
        hostPort      = var.app_port
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      # environment = [{ name = "ENV", value = "prod" }]
      # secrets     = [{ name = "API_KEY", valueFrom = "arn:aws:ssm:us-east-1:123456789012:parameter/your_key" }]
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = { Project = var.project_name }
}

# ECS Service (Fargate) behind ALB
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"        # must match container_definitions[].name
    container_port   = var.app_port # 80 by default
  }

  depends_on = [aws_lb_listener.http]
  tags       = { Project = var.project_name }
}