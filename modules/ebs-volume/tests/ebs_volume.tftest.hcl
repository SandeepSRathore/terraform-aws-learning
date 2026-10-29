mock_provider "aws" {}

variables {
  name              = "test-data"
  availability_zone = "us-east-1a"
}

run "standalone_volume" {
  command = plan

  assert {
    condition     = aws_ebs_volume.this.encrypted && aws_ebs_volume.this.size == 1
    error_message = "Expected an encrypted 1 GB volume"
  }

  assert {
    condition     = length(aws_volume_attachment.this) == 0
    error_message = "Should not attach unless attach = true"
  }
}

run "attached_volume" {
  command = plan

  variables {
    attach      = true
    instance_id = "i-0123456789abcdef0"
  }

  assert {
    condition     = aws_volume_attachment.this[0].instance_id == "i-0123456789abcdef0"
    error_message = "Should attach to the given instance"
  }
}

run "attach_without_instance_fails" {
  command = plan

  variables {
    attach = true
  }

  expect_failures = [aws_volume_attachment.this]
}

run "rejects_io1" {
  command = plan

  variables {
    type = "io1"
  }

  expect_failures = [var.type]
}
