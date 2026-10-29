mock_provider "aws" {
  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:us-east-1:123456789012:mock-topic"
    }
  }

  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-east-1:123456789012:mock-queue"
    }
  }
}

run "logs_metric_alarm_chain" {
  command = apply

  assert {
    condition     = aws_cloudwatch_log_metric_filter.errors.metric_transformation[0].name == aws_cloudwatch_metric_alarm.too_many_errors.metric_name
    error_message = "The alarm must watch the metric the filter produces"
  }

  assert {
    condition     = contains(aws_cloudwatch_metric_alarm.too_many_errors.alarm_actions, aws_sns_topic.alerts.arn)
    error_message = "The alarm should notify the SNS topic"
  }

  assert {
    condition     = aws_cloudwatch_log_group.app.retention_in_days == 14
    error_message = "Logs should expire after 14 days"
  }
}
