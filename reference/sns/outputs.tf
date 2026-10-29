output "topic_arn" {
  value = aws_sns_topic.orders.arn
}

output "all_orders_queue_url" {
  value = aws_sqs_queue.all_orders.id
}

output "big_orders_queue_url" {
  value = aws_sqs_queue.big_orders.id
}
