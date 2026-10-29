mock_provider "aws" {}

variables {
  name = "test-app"
}

run "trusts_ec2_and_allows_ssm_by_default" {
  command = plan

  assert {
    condition     = jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Principal.Service == "ec2.amazonaws.com"
    error_message = "Only EC2 may assume this role"
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.ssm) == 1
    error_message = "Session Manager access should be on by default"
  }

  assert {
    condition     = length(aws_iam_role_policy.this) == 0
    error_message = "No inline policy unless statements are given"
  }

  assert {
    condition     = aws_iam_instance_profile.this.role == aws_iam_role.this.name
    error_message = "The profile must wrap the role"
  }
}

run "custom_statements_become_inline_policy" {
  command = plan

  variables {
    enable_ssm = false
    policy_statements = [{
      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::my-bucket/app.jar"]
    }]
  }

  assert {
    condition     = jsondecode(output.policy_json).Statement[0].Resource[0] == "arn:aws:s3:::my-bucket/app.jar"
    error_message = "The inline policy should grant exactly the given resource"
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.ssm) == 0
    error_message = "SSM should be off when disabled"
  }
}
