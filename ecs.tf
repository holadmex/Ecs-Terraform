# Create ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = "Full-stack-web-app"
}

# Create CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/example-task"
  retention_in_days = 7
}

# ECS Task Definition
resource "aws_ecs_task_definition" "task" {
  family = "web-app-task"
  container_definitions = jsonencode([
    {
      name      = "frontend-container"
      image     = "nginx:latest"
      cpu       = 512
      memory    = 1024
      essential = true
      environment = [
        { name = "ENV_VAR_1", value = "value1" },
        { name = "ENV_VAR_2", value = "value2" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
}


# ECS Service
resource "aws_ecs_service" "service" {
  name            = "web-app-service"
  cluster         = aws_ecs_cluster.cluster.arn
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["subnet-3a4cc635", "subnet-ba203d85"] # Replace with your Subnet IDs
    security_groups = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_iam_policy_attachment.ecs_task_execution_attachment]
}
