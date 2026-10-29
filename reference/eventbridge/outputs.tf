output "bus_name" {
  value = aws_cloudwatch_event_bus.shop.name
}

output "queue_url" {
  value = aws_sqs_queue.big_orders.id
}
