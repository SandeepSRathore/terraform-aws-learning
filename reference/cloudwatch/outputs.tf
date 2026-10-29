output "log_group" {
  value = aws_cloudwatch_log_group.app.name
}

output "alarm_name" {
  value = aws_cloudwatch_metric_alarm.too_many_errors.alarm_name
}

output "alerts_inbox_url" {
  value = aws_sqs_queue.alerts_inbox.id
}
