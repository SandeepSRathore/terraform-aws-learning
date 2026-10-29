# EventBridge = an event router. Services publish events ("OrderPlaced") to a
# bus; RULES match events by pattern and send them to TARGETS (Lambda, SQS,
# Step Functions, ...). Publishers don't know who consumes, so adding a new
# consumer means adding a rule, not changing the publisher.
#
# vs SNS: SNS filters on message attributes and fans out to subscribers;
# EventBridge matches on the event's JSON content, has schedules (cron),
# and receives events from 200+ AWS services and SaaS apps.
#
# Shown here: a custom bus, a content-based rule -> SQS, and a schedule.

resource "aws_cloudwatch_event_bus" "shop" {
  name = "shop"
}

# Matches only big orders from our app. Numeric matching and prefix/anything-but
# operators exist too; see "EventBridge event patterns" in the AWS docs.
resource "aws_cloudwatch_event_rule" "big_orders" {
  name           = "big-orders"
  event_bus_name = aws_cloudwatch_event_bus.shop.name

  event_pattern = jsonencode({
    source        = ["app.orders"]
    "detail-type" = ["OrderPlaced"]
    detail = {
      amount = [{ numeric = [">=", 100] }]
    }
  })
}

resource "aws_sqs_queue" "big_orders" {
  name = "eventbridge-big-orders"
}

resource "aws_cloudwatch_event_target" "to_sqs" {
  rule           = aws_cloudwatch_event_rule.big_orders.name
  event_bus_name = aws_cloudwatch_event_bus.shop.name
  arn            = aws_sqs_queue.big_orders.arn

  # Optional: reshape the event before delivery (here, keep only `detail`).
  input_path = "$.detail"
}

# Same idea as the SNS example: the queue must allow EventBridge to send.
resource "aws_sqs_queue_policy" "big_orders" {
  queue_url = aws_sqs_queue.big_orders.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.big_orders.arn
      Condition = { ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.big_orders.arn } }
    }]
  })
}

# Schedules run on the DEFAULT bus. cron(min hour day-of-month month day-of-week year).
# DISABLED here so it doesn't fire; give it a target to make it useful.
# (For new work, AWS recommends the separate EventBridge Scheduler: aws_scheduler_schedule.)
resource "aws_cloudwatch_event_rule" "nightly" {
  name                = "nightly-report"
  schedule_expression = "cron(0 2 * * ? *)" # 02:00 UTC every day
  state               = "DISABLED"
}
