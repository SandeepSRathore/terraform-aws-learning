mock_provider "aws" {}

variables {
  name      = "test-web"
  subnet_id = "subnet-12345678"
}

run "looks_up_ami_when_not_given" {
  command = plan

  assert {
    condition     = length(data.aws_ami.al2023) == 1
    error_message = "Should look up the latest Amazon Linux AMI"
  }

  assert {
    condition     = aws_instance.this.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be enforced"
  }

  assert {
    condition     = aws_instance.this.root_block_device[0].encrypted
    error_message = "Root volume must be encrypted"
  }
}

run "uses_given_ami" {
  command = plan

  variables {
    ami_id        = "ami-0abcdef1234567890"
    instance_type = "t3.small"
  }

  assert {
    condition     = length(data.aws_ami.al2023) == 0
    error_message = "Should skip the AMI lookup"
  }

  assert {
    condition     = aws_instance.this.ami == "ami-0abcdef1234567890"
    error_message = "Should boot the AMI we passed in"
  }
}

run "attaches_instance_profile" {
  command = plan

  variables {
    iam_instance_profile = "test-web-profile"
  }

  assert {
    condition     = aws_instance.this.iam_instance_profile == "test-web-profile"
    error_message = "The instance should get the IAM role through its instance profile"
  }
}

# `command = apply` against the mock "creates" the instance with fake
# values, so we can check outputs that only exist after creation.
run "outputs_after_apply" {
  command = apply

  assert {
    condition     = output.id != null && output.public_ip != null
    error_message = "Instance ID and public IP should be known after apply"
  }
}

run "rejects_tiny_disk" {
  command = plan

  variables {
    root_volume_size = 2
  }

  expect_failures = [var.root_volume_size]
}
