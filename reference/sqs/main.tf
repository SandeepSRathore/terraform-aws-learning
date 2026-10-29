# SQS = a queue. Producers send messages; consumers poll, process, then DELETE
# them. A message that isn't deleted becomes visible again after the
# visibility timeout, so a crashed consumer never loses work.
#
# Shown here:
#   - standard queue (at-least-once delivery, best-effort ordering)
#   - dead-letter queue (DLQ): where a message goes after N failed attempts
#   - FIFO queue (exactly-once processing, strict order per message group)

resource "aws_sqs_queue" "dlq" {
  name                      = "orders-dlq"
  message_retention_seconds = 1209600 # 14 days (the max): time to investigate failures
}

resource "aws_sqs_queue" "orders" {
  name = "orders"

  visibility_timeout_seconds = 30     # hidden from other consumers while one works on it
  message_retention_seconds  = 345600 # 4 days, the default
  receive_wait_time_seconds  = 10     # long polling: fewer empty (billed) responses
  sqs_managed_sse_enabled    = true   # encryption at rest, free

  # After 3 receives without a delete, SQS moves the message to the DLQ.
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# Only `orders` may use the DLQ as its dead-letter target.
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.orders.arn]
  })
}

# FIFO names must end in .fifo. Content-based deduplication drops identical
# messages sent within 5 minutes, so retries by the producer are safe.
resource "aws_sqs_queue" "payments" {
  name                        = "payments.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}
