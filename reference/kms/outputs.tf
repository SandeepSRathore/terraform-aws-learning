output "key_id" {
  value = aws_kms_key.app.key_id
}

output "alias" {
  value = aws_kms_alias.app.name
}
