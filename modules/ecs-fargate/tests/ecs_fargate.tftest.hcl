mock_provider "aws" {}

variables {
  name               = "test-app"
  subnet_ids         = ["subnet-aaaa1111", "subnet-bbbb2222"]
  security_group_ids = ["sg-12345678"]
}

run "task_definition_is_fargate_ready" {
  command = plan

  assert {
    condition     = aws_ecs_task_definition.this.network_mode == "awsvpc"
    error_message = "Fargate requires awsvpc networking"
  }

  assert {
    condition     = aws_ecs_task_definition.this.cpu == "256" && aws_ecs_task_definition.this.memory == "512"
    error_message = "Expected the smallest Fargate size by default"
  }

  # The container definition is JSON; decode it to inspect the fields.
  assert {
    condition     = jsondecode(aws_ecs_task_definition.this.container_definitions)[0].portMappings[0].containerPort == 80
    error_message = "Container should expose port 80"
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.name == "/ecs/test-app"
    error_message = "Log group should be named after the app"
  }
}

run "custom_image_and_env" {
  command = plan

  variables {
    container_image = "public.ecr.aws/docker/library/httpd:2.4"
    desired_count   = 2
    environment     = { APP_ENV = "dev" }
  }

  assert {
    condition     = jsondecode(aws_ecs_task_definition.this.container_definitions)[0].image == "public.ecr.aws/docker/library/httpd:2.4"
    error_message = "Should run the requested image"
  }

  assert {
    condition     = jsondecode(aws_ecs_task_definition.this.container_definitions)[0].environment[0].name == "APP_ENV"
    error_message = "Environment map should become ECS name/value pairs"
  }

  assert {
    condition     = aws_ecs_service.this.desired_count == 2
    error_message = "Service should run 2 tasks"
  }
}

run "rejects_invalid_cpu" {
  command = plan

  variables {
    cpu = 300
  }

  expect_failures = [var.cpu]
}
