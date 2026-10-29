mock_provider "aws" {
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-east-1:123456789012:mock-queue"
    }
  }
}

run "dlq_and_fifo" {
  command = apply

  assert {
    condition     = jsondecode(aws_sqs_queue.orders.redrive_policy).maxReceiveCount == 3
    error_message = "Messages should move to the DLQ after 3 failed receives"
  }

  assert {
    condition     = aws_sqs_queue.payments.fifo_queue && endswith(aws_sqs_queue.payments.name, ".fifo")
    error_message = "FIFO queue names must end in .fifo"
  }
}
