locals {
  application_name = "tf-notejam"
  launch_type = "EC2"
  image_tag = "latest"
}
###############
# Cloudwatch Logs
###############
resource "aws_cloudwatch_log_group" "ecsTaskLogger" {
  name = "${local.application_name}-cloudwatch"
  retention_in_days = 3
}

###############
# ECR
###############
resource "aws_ecr_repository" "main" {
  name                 = "notejam"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action       = {
        type = "expire"
      }
      selection     = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}
################
# ECS FARGATE
################
resource "aws_ecs_cluster" "notejam" {
  name = local.application_name
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  tags = {
    Name = "${local.application_name}-cluster"
    Project = local.application_name
  }
}

resource "aws_ecs_task_definition" "notejam" {
  family                   = local.application_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsInstanceRole.arn
  container_definitions = jsonencode([
    {
      name         = local.application_name
      image        = "${aws_ecr_repository.main.repository_url}:${local.image_tag}"
      essential    = true
      # environment = var.container_environment
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 80
          hostPort      = 80
        }
      ]
    }])
}

resource "aws_ecs_service" "main" {
  depends_on = [
    aws_lb.main,
    aws_ecs_task_definition.notejam
  ]
  name            = "${local.application_name}-service"
  iam_role        = aws_iam_role.ecsServiceRole.arn
  cluster         = aws_ecs_cluster.notejam.id
  task_definition = aws_ecs_task_definition.notejam.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = [
      aws_subnet.private_subnet_a.id,
      aws_subnet.private_subnet_b.id
    ]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.arn
    container_name   = local.application_name
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
