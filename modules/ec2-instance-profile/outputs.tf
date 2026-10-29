output "instance_profile_name" {
  description = "Pass this to the ec2-instance module's iam_instance_profile"
  value       = aws_iam_instance_profile.this.name
}

output "role_name" {
  value = aws_iam_role.this.name
}

output "policy_json" {
  description = "The inline permissions as an IAM policy document, or null"
  value       = one(aws_iam_role_policy.this[*].policy)
}
