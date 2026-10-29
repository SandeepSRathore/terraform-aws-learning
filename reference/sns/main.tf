# SNS = publish/subscribe. A publisher sends ONE message to a topic and SNS
# pushes a copy to EVERY subscriber (SQS queues, Lambdas, HTTP endpoints,
# email, SMS). The classic pattern is "fan-out": topic -> several SQS queues,
# so each consumer gets its own copy and can fail independently.
#
# Shown here:
#   - topic -> two SQS queues (fan-out)
#   - a filter policy: one queue only gets orders with amount >= 100
#   - the queue policy SNS needs to be allowed to write into a queue

resource "aws_sns_topic" "orders" {
  name = "order-events"
}

resource "aws_sqs_queue" "all_orders" {
  name = "all-orders"
}

resource "aws_sqs_queue" "big_orders" {
  name = "big-orders"
}

# A queue rejects everyone by default. This lets the topic (and only it) send.
data "aws_iam_policy_document" "sns_to_sqs" {
  for_each = {
    all = aws_sqs_queue.all_orders.arn
    big = aws_sqs_queue.big_orders.arn
  }

  statement {
    actions   = ["sqs:SendMessage"]
    resources = [each.value]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.orders.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "all_orders" {
  queue_url = aws_sqs_queue.all_orders.id
  policy    = data.aws_iam_policy_document.sns_to_sqs["all"].json
}

resource "aws_sqs_queue_policy" "big_orders" {
  queue_url = aws_sqs_queue.big_orders.id
  policy    = data.aws_iam_policy_document.sns_to_sqs["big"].json
}

# raw_message_delivery = true: the queue gets the message body as published,
# instead of wrapped in an SNS JSON envelope.
resource "aws_sns_topic_subscription" "all_orders" {
  topic_arn            = aws_sns_topic.orders.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.all_orders.arn
  raw_message_delivery = true
}

resource "aws_sns_topic_subscription" "big_orders" {
  topic_arn            = aws_sns_topic.orders.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.big_orders.arn
  raw_message_delivery = true

  # Filters on message ATTRIBUTES (not the body, unless filter_policy_scope = "MessageBody").
  filter_policy = jsonencode({
    amount = [{ numeric = [">=", 100] }]
  })
}

# Email subscriptions need a human to click a confirmation link, so they
# can't be fully automated. Shown for reference only:
# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.orders.arn
#   protocol  = "email"
#   endpoint  = "you@example.com"
# }
