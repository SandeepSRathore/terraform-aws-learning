# Application Load Balancer (ALB) = one public entry point that spreads HTTP
# traffic across many targets (EC2 instances, containers, IPs, Lambdas) and
# routes by path or host name. It health-checks targets and stops sending
# traffic to unhealthy ones.
#
#   load balancer -> lives in 2+ subnets (different AZs) with a security group
#   listener      -> a port + protocol (HTTP 80, HTTPS 443 with an ACM cert)
#   rules         -> "if path is /api/* then forward to target group X"
#   target group  -> the set of targets plus their health check
#
# This example uses the account's DEFAULT VPC and answers with fixed
# responses, so it works without any servers behind it.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "alb" {
  name        = "demo-alb"
  description = "HTTP from anywhere to the load balancer"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_lb" "web" {
  name               = "demo-alb"
  load_balancer_type = "application"
  internal           = false # true = only reachable inside the VPC
  security_groups    = [aws_security_group.alb.id]
  subnets            = slice(data.aws_subnets.default.ids, 0, 2) # an ALB needs 2+ AZs
}

# Where /api/* traffic would go. Register targets with
# aws_lb_target_group_attachment (instances) or let ECS register tasks.
resource "aws_lb_target_group" "api" {
  name        = "demo-api"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip" # "instance" for EC2, "ip" for Fargate tasks, "lambda" for Lambda
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30 # seconds to let in-flight requests finish
}

# Anything not matched by a rule gets this answer.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "default: no rule matched"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "health" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10 # lower number = checked first

  condition {
    path_pattern {
      values = ["/health"]
    }
  }

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"status\":\"ok\"}"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# Typical HTTPS setup (needs a certificate, see ../acm):
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.web.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn   = aws_acm_certificate.site.arn
#   default_action { ... }
# }
# and redirect HTTP to HTTPS with default_action { type = "redirect" ... }.
