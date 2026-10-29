# The rule ID (sgr-...) is assigned by AWS. If it changes, the rule was
# deleted and a new one was created in its place.

output "count_rules" {
  value = [
    for r in aws_vpc_security_group_ingress_rule.with_count :
    "${r.description} port ${r.from_port} = ${r.security_group_rule_id}"
  ]
}

output "for_each_rules" {
  value = {
    for k, r in aws_vpc_security_group_ingress_rule.with_for_each :
    k => "port ${r.from_port} = ${r.security_group_rule_id}"
  }
}
