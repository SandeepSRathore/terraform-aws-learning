mock_provider "aws" {}

variables {
  name = "test-eip"
}

run "unattached_by_default" {
  command = plan

  # Note: we can't assert `aws_eip.this.instance == null` here. `instance` is
  # a COMPUTED attribute, so when left unset its value is "known after apply".

  assert {
    condition     = aws_eip.this.tags["Name"] == "test-eip"
    error_message = "The IP should be tagged with its name"
  }

  assert {
    condition     = aws_eip.this.domain == "vpc"
    error_message = "Elastic IPs must be in the VPC domain"
  }
}

run "attaches_to_instance" {
  command = plan

  variables {
    instance_id = "i-0123456789abcdef0"
  }

  assert {
    condition     = aws_eip.this.instance == "i-0123456789abcdef0"
    error_message = "The IP should attach to the given instance"
  }
}
