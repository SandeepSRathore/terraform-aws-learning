mock_provider "aws" {
  mock_data "aws_subnets" {
    defaults = {
      ids = ["subnet-aaaa1111", "subnet-bbbb2222", "subnet-cccc3333"]
    }
  }

  mock_resource "aws_lb" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/demo-alb/abc"
    }
  }

  mock_resource "aws_lb_listener" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/demo-alb/abc/def"
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/demo-api/abc"
    }
  }
}

run "listener_rules" {
  command = plan

  assert {
    condition     = length(aws_lb.web.subnets) == 2 && aws_lb.web.load_balancer_type == "application"
    error_message = "ALB should span 2 subnets"
  }

  assert {
    condition     = aws_lb_listener_rule.health.priority < aws_lb_listener_rule.api.priority
    error_message = "/health should be evaluated before /api/*"
  }

  assert {
    condition     = aws_lb_target_group.api.health_check[0].path == "/health"
    error_message = "Targets should be health-checked on /health"
  }
}
