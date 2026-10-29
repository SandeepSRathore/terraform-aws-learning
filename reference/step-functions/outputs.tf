output "state_machine_arn" {
  value = aws_sfn_state_machine.orders.arn
}

output "table_name" {
  value = aws_dynamodb_table.orders.name
}
