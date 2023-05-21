resource "aws_ecr_repository" "hello_repo" {
  name                 = "hello-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecs_cluster" "hello_cluster" {
  name = local.application_name
}

data "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "hello_taskdef" {
  container_definitions = jsonencode(
    [
      {
        essential = true
        image     = "${aws_ecr_repository.hello_repo.repository_url}:hello-app"
        name      = "hello-app"
        portMappings = [
          {
            appProtocol   = "http"
            containerPort = 5000
            hostPort      = 5000
            name          = "hello-app-5000-tcp"
            protocol      = "tcp"
          },
        ]
      },
    ]
  )
  cpu                = "256"
  execution_role_arn = data.aws_iam_role.ecs_task_role.arn
  family             = "hello-app-taskdef"
  memory             = "512"
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "hello_app_service" {
  cluster                            = aws_ecs_cluster.hello_cluster.arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 2
  enable_ecs_managed_tags            = true
  enable_execute_command             = false
  health_check_grace_period_seconds  = 0
  launch_type                        = "FARGATE"
  name                               = "hello-app-service"
  platform_version                   = "LATEST"
  propagate_tags                     = "NONE"
  scheduling_strategy                = "REPLICA"
  task_definition                    = aws_ecs_task_definition.hello_taskdef.arn

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  deployment_controller {
    type = "ECS"
  }
  load_balancer {
    container_name   = "hello-app"
    container_port   = 5000
    target_group_arn = aws_lb_target_group.hello_tg.arn
  }
  network_configuration {
    assign_public_ip = false
    security_groups = [
      aws_security_group.hello_sg.id,
    ]
    subnets = [
      aws_subnet.cluster_subnet_1.id,
      aws_subnet.cluster_subnet_2.id,
    ]
  }
}

resource "aws_lb" "hello_lb" {
  enable_cross_zone_load_balancing = true
  name                             = "hello-lb"
  security_groups = [
    aws_security_group.hello_sg.id,
  ]
  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
  ]
  subnet_mapping {
    subnet_id = aws_subnet.public_subnet_1.id
  }
  subnet_mapping {
    subnet_id = aws_subnet.public_subnet_2.id
  }
}

resource "aws_security_group" "hello_sg" {
  description = "hello-sg"
  egress {
    cidr_blocks = [
      "0.0.0.0/0",
    ]
    from_port = 0
    protocol  = "-1"

    to_port = 0
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0",
    ]
    from_port = 0
    ipv6_cidr_blocks = [
      "::/0",
    ]
    protocol = "tcp"
    to_port  = 65535
  }

  name   = "hello-sg"
  vpc_id = aws_vpc.omurVPC.id
}

resource "aws_lb_target_group" "hello_tg" {
  deregistration_delay = "300"
  ip_address_type      = "ipv4"
  name                 = "hello-tg"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = aws_vpc.omurVPC.id

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}