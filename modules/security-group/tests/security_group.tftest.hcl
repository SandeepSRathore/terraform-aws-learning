mock_provider "aws" {}

variables {
  name   = "test-sg"
  vpc_id = "vpc-12345678"
  ingress_rules = {
    http = { description = "HTTP", port = 80, cidr_ipv4 = "0.0.0.0/0" }
    ssh  = { description = "SSH from me", port = 22, cidr_ipv4 = "203.0.113.10/32" }
  }
}

run "one_rule_per_map_entry" {
  command = plan

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 2
    error_message = "Expected one rule per ingress_rules entry"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["ssh"].from_port == 22
    error_message = "The ssh rule should open port 22"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["http"].ip_protocol == "tcp"
    error_message = "protocol should default to tcp"
  }
}

run "egress_can_be_disabled" {
  command = plan

  variables {
    allow_all_egress = false
  }

  assert {
    condition     = length(aws_vpc_security_group_egress_rule.all) == 0
    error_message = "No egress rule expected"
  }
}

run "blocks_ssh_from_internet" {
  command = plan

  variables {
    ingress_rules = {
      ssh = { description = "oops", port = 22, cidr_ipv4 = "0.0.0.0/0" }
    }
  }

  expect_failures = [var.ingress_rules]
}
