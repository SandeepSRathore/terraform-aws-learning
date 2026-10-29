mock_provider "aws" {
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-east-1:123456789012:mock-queue"
    }
  }
}

run "rule_pattern_and_schedule" {
  command = plan

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.big_orders.event_pattern).source == ["app.orders"]
    error_message = "Rule should only match events from app.orders"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.nightly.state == "DISABLED"
    error_message = "The example schedule should stay disabled"
  }
}
