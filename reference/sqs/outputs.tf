output "queue_url" {
  value = aws_sqs_queue.orders.id # for SQS, id IS the queue URL
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.id
}

output "fifo_queue_url" {
  value = aws_sqs_queue.payments.id
}
