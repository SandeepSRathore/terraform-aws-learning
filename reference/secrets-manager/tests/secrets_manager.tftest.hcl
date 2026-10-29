mock_provider "aws" {}

# The random provider is real here: it just generates a string locally.

run "json_secret" {
  command = apply

  assert {
    condition     = jsondecode(aws_secretsmanager_secret_version.db.secret_string).username == "app_user"
    error_message = "Secret should hold JSON credentials"
  }

  assert {
    condition     = length(jsondecode(aws_secretsmanager_secret_version.db.secret_string).password) == 24
    error_message = "Password should be 24 characters"
  }
}
