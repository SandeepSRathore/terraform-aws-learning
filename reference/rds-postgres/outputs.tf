output "endpoint" {
  value = aws_db_instance.main.address
}

output "port" {
  value = aws_db_instance.main.port
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "master_secret_arn" {
  description = "Secrets Manager secret holding the generated master password"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}
