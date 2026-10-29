# CloudWatch = AWS's monitoring service.
#   Logs    -> log groups (one per app/function) hold log streams of events
#   Metrics -> numbers over time (CPU, request count, or your own custom ones)
#   Alarms  -> watch a metric; when it crosses a threshold, notify/act
#
# Shown here, the classic chain:
#   app logs "ERROR ..." -> metric filter counts them -> alarm on the count
#   -> SNS topic -> (email/Slack/pager; here an SQS queue we can inspect)

resource "aws_cloudwatch_log_group" "app" {
  name              = "/demo/app"
  retention_in_days = 14 # default is "never expire", which grows cost forever
}

# Turns matching log lines into a metric, with no code changes in the app.
resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "error-count"
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = "ERROR" # also supports JSON patterns: { $.level = "error" }

  metric_transformation {
    name          = "ErrorCount"
    namespace     = "Demo/App"
    value         = "1" # each matching line adds 1
    default_value = "0" # report 0 when nothing matched, so the alarm sees data
  }
}

resource "aws_sns_topic" "alerts" {
  name = "demo-alerts"
}

resource "aws_cloudwatch_metric_alarm" "too_many_errors" {
  alarm_name          = "app-too-many-errors"
  alarm_description   = "More than 5 errors in a minute"
  namespace           = "Demo/App"
  metric_name         = "ErrorCount"
  statistic           = "Sum"
  period              = 60 # seconds per data point
  evaluation_periods  = 1  # how many periods must breach
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn] # on entering ALARM
  ok_actions    = [aws_sns_topic.alerts.arn] # on returning to OK
}

# ---- a queue standing in for email/Slack, so the exercise can read alerts ----
resource "aws_sqs_queue" "alerts_inbox" {
  name = "demo-alerts-inbox"
}

resource "aws_sqs_queue_policy" "alerts_inbox" {
  queue_url = aws_sqs_queue.alerts_inbox.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.alerts_inbox.arn
      Condition = { ArnEquals = { "aws:SourceArn" = aws_sns_topic.alerts.arn } }
    }]
  })
}

resource "aws_sns_topic_subscription" "alerts_inbox" {
  topic_arn            = aws_sns_topic.alerts.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.alerts_inbox.arn
  raw_message_delivery = true
}

# A dashboard is just JSON describing widgets.
resource "aws_cloudwatch_dashboard" "app" {
  dashboard_name = "demo-app"
  dashboard_body = jsonencode({
    widgets = [{
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        title   = "Errors per minute"
        region  = var.aws_region
        metrics = [["Demo/App", "ErrorCount"]]
        stat    = "Sum"
        period  = 60
      }
    }]
  })
}
