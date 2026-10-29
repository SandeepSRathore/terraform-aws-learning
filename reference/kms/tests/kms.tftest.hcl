mock_provider "aws" {}

run "rotating_key_with_alias" {
  command = plan

  assert {
    condition     = aws_kms_key.app.enable_key_rotation && aws_kms_key.app.deletion_window_in_days == 7
    error_message = "Key should rotate and have a 7 day deletion window"
  }

  assert {
    condition     = startswith(aws_kms_alias.app.name, "alias/")
    error_message = "Alias names must start with alias/"
  }
}
