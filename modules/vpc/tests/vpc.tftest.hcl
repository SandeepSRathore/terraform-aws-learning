# Run with: terraform init && terraform test
# mock_provider = a fake AWS. No account, no credentials, nothing created.
mock_provider "aws" {}

# A mock returns random values for data sources. Override this one so the
# module gets realistic availability zone names to work with.
override_data {
  target = data.aws_availability_zones.available
  values = {
    names = ["us-east-1a", "us-east-1b", "us-east-1c"]
  }
}

variables {
  name = "test"
}

run "creates_two_subnets_by_default" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Expected 2 public subnets by default"
  }

  assert {
    condition     = aws_subnet.public[1].cidr_block == "10.0.1.0/24"
    error_message = "Second subnet should be 10.0.1.0/24"
  }

  assert {
    condition     = aws_subnet.public[1].availability_zone == "us-east-1b"
    error_message = "Subnets should be spread across availability zones"
  }
}

run "custom_cidr_and_count" {
  command = plan

  variables {
    cidr_block          = "172.16.0.0/16"
    public_subnet_count = 3
  }

  assert {
    condition     = aws_subnet.public[2].cidr_block == "172.16.2.0/24"
    error_message = "Subnets should be carved from the custom CIDR"
  }
}

run "rejects_too_many_subnets" {
  command = plan

  variables {
    public_subnet_count = 10
  }

  # This run PASSES only if the validation rule rejects the input.
  expect_failures = [var.public_subnet_count]
}
