mock_provider "aws" {}

run "hierarchy_and_types" {
  command = plan

  assert {
    condition     = aws_ssm_parameter.api_key.type == "SecureString"
    error_message = "Secrets must be SecureString"
  }

  assert {
    condition     = alltrue([for p in [aws_ssm_parameter.log_level, aws_ssm_parameter.allowed_origins, aws_ssm_parameter.api_key] : startswith(p.name, "/app/dev/")])
    error_message = "All parameters should live under /app/dev/"
  }
}
