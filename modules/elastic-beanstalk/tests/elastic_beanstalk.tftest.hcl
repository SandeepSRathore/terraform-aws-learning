mock_provider "aws" {}

override_data {
  target = data.aws_elastic_beanstalk_solution_stack.this
  values = {
    name = "64bit Amazon Linux 2023 v4.5.0 running Python 3.12"
  }
}

variables {
  name       = "test-eb"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-aaaa1111", "subnet-bbbb2222"]
}

run "single_instance_python" {
  command = plan

  assert {
    condition     = aws_elastic_beanstalk_environment.this.solution_stack_name == "64bit Amazon Linux 2023 v4.5.0 running Python 3.12"
    error_message = "Environment should use the platform found by the data source"
  }

  assert {
    condition = contains(
      [for s in aws_elastic_beanstalk_environment.this.setting : s.value if s.name == "EnvironmentType"],
      "SingleInstance"
    )
    error_message = "Should default to a cheap single-instance environment"
  }

  assert {
    condition = contains(
      [for s in aws_elastic_beanstalk_environment.this.setting : s.value if s.name == "Subnets"],
      "subnet-aaaa1111,subnet-bbbb2222"
    )
    error_message = "Subnets should be passed as a comma-separated string"
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.service) == 2
    error_message = "Service role needs both managed policies"
  }
}

run "env_vars_become_settings" {
  command = plan

  variables {
    env_vars = { APP_ENV = "dev", DEBUG = "false" }
  }

  assert {
    condition = length([
      for s in aws_elastic_beanstalk_environment.this.setting : s
      if s.namespace == "aws:elasticbeanstalk:application:environment"
    ]) == 2
    error_message = "Each env var should become one setting"
  }
}

run "rejects_unknown_environment_type" {
  command = plan

  variables {
    environment_type = "Serverless"
  }

  expect_failures = [var.environment_type]
}
