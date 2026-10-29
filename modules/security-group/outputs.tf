output "id" {
  value = aws_security_group.this.id
}

output "rule_names" {
  description = "Names of the inbound rules that were created"
  value       = keys(aws_vpc_security_group_ingress_rule.this)
}
