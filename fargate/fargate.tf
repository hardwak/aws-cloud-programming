resource "aws_ecs_cluster" "cluster" {
  name = "fargate-cluster"
}

data "aws_iam_role" "iam_role" {
  name = "LabRole"
}

module "frontend_def" {
  source = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=v0.61.2"

  container_name  = "frontend-container"
  container_image = "hardwak/cloud_frontend:latest"

  port_mappings = [
    {
      containerPort = 5173
      hostPort      = 5173
      protocol      = "tcp"
    }
  ]

  environment = [
    {
      name  = "PUBLIC_API_BASE_URL"
      value = "http://${aws_lb.app_alb.dns_name}:8081"
    }
  ]
}

module "backend_def" {
  source = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=v0.61.2"

  container_name  = "backend-container"
  container_image = "hardwak/cloud-backend:latest"

  port_mappings = [
    {
      containerPort = 8081
      hostPort      = 8081
      protocol      = "tcp"
    }
  ]

  environment = [
    {
      name  = "CORS_ALLOWED_ORIGINS"
      value = "http://${aws_lb.app_alb.dns_name}:5173"
    },
    {
      name  = "SPRING_DATASOURCE_URL"
      value = "jdbc:postgresql://${aws_db_instance.app_db.endpoint}/${aws_db_instance.app_db.db_name}"
    },
    {
      name  = "SPRING_DATASOURCE_USERNAME"
      value = "${aws_db_instance.app_db.username}"
    },
    {
      name  = "SPRING_DATASOURCE_PASSWORD"
      value = "${aws_db_instance.app_db.password}"
    },
    {
      name  = "SPRING_JPA_HIBERNATE_DDL_AUTO"
      value = "update"
    },
    {
      name  = "SPRING_JPA_DATABASE_PLATFORM"
      value = "org.hibernate.dialect.PostgreSQLDialect"
    }
  ]
}

resource "aws_ecs_task_definition" "backend_task" {
  family                   = "backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024

  execution_role_arn = data.aws_iam_role.iam_role.arn
  task_role_arn      = data.aws_iam_role.iam_role.arn

  container_definitions = jsonencode([
    jsondecode(module.backend_def.json_map_encoded)
  ])
}

resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024

  execution_role_arn = data.aws_iam_role.iam_role.arn
  task_role_arn      = data.aws_iam_role.iam_role.arn

  container_definitions = jsonencode([
    jsondecode(module.frontend_def.json_map_encoded)
  ])
}

resource "aws_ecs_service" "backend_service" {
  name        = "backend-service"
  cluster     = aws_ecs_cluster.cluster.id
  launch_type = "FARGATE"

  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.backend_sg.id] 
    subnets          = [aws_subnet.public.id, aws_subnet.public-2.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend-container"
    container_port   = 8081
  }
}

resource "aws_ecs_service" "frontend_service" {
  name        = "frontend-service"
  cluster     = aws_ecs_cluster.cluster.id
  launch_type = "FARGATE"

  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.frontend_sg.id]
    subnets          = [aws_subnet.public.id, aws_subnet.public-2.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend-container"
    container_port   = 5173
  }
}