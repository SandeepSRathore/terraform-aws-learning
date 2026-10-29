mock_provider "aws" {
  # aws_lambda_function validates that role looks like a real ARN.
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }
}

# The archive provider is NOT mocked: it really zips tests/fixtures/hello,
# which is cheap and proves the source_dir wiring works.

variables {
  name       = "test-fn"
  source_dir = "./tests/fixtures/hello"
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_lambda_function.this.runtime == "python3.13" && aws_lambda_function.this.handler == "handler.handler"
    error_message = "Expected the default Python runtime and handler"
  }

  assert {
    condition     = aws_lambda_function.this.timeout == 10 && aws_lambda_function.this.memory_size == 128
    error_message = "Expected a 10 second timeout and 128 MB by default"
  }

  # Lambda writes to /aws/lambda/<name>; creating it ourselves sets retention.
  assert {
    condition     = aws_cloudwatch_log_group.this.name == "/aws/lambda/test-fn"
    error_message = "Log group must match the name Lambda writes to"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.logs.policy_arn == "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    error_message = "The function must be allowed to write logs"
  }

  assert {
    condition     = length(aws_iam_role_policy.extra) == 0
    error_message = "No extra permissions unless policy_statements is set"
  }

  # The hash makes Terraform redeploy whenever the code changes.
  assert {
    condition     = aws_lambda_function.this.source_code_hash == data.archive_file.this.output_base64sha256
    error_message = "Code changes must trigger a redeploy"
  }
}

run "extra_permissions_and_env" {
  command = plan

  variables {
    environment = { GREETING = "hi" }
    policy_statements = [
      { actions = ["s3:GetObject"], resources = ["arn:aws:s3:::my-bucket/in/*"] },
    ]
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.extra[0].policy).Statement[0].Action == ["s3:GetObject"]
    error_message = "policy_statements should become an inline IAM policy"
  }

  assert {
    condition     = aws_lambda_function.this.environment[0].variables.GREETING == "hi"
    error_message = "Environment variables should reach the function"
  }
}

run "rejects_too_long_timeout" {
  command = plan

  variables {
    timeout = 901
  }

  expect_failures = [var.timeout]
}
