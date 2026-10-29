output "alice_arn" {
  value = aws_iam_user.alice.arn
}

output "deployer_role_arn" {
  value = aws_iam_role.deployer.arn
}

output "alice_access_key_id" {
  value = aws_iam_access_key.alice.id
}

output "alice_secret_access_key" {
  value     = aws_iam_access_key.alice.secret
  sensitive = true # hidden in plan/apply output; `terraform output -raw` still shows it
}
