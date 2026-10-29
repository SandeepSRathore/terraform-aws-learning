output "secret_name" {
  value = aws_secretsmanager_secret.db.name
}

# Never output the password itself; apps read it from Secrets Manager.
