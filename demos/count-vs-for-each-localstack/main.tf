#   terraform init
#   terraform apply -auto-approve                          # 3 rules in each group
#   terraform plan  -var-file=remove-http.tfvars           # remove the first one
#   terraform apply -var-file=remove-http.tfvars -auto-approve
#   terraform output                                       # which rule IDs survived?

variable "rules" {
  description = "Firewall rules, in order"
  type = list(object({
    name = string
    port = number
  }))
  default = [
    { name = "http", port = 80 },
    { name = "https", port = 443 },
    { name = "ssh", port = 22 },
  ]
}

# LocalStack, like real AWS, has a default VPC in every region.
data "aws_vpc" "default" {
  default = true
}

# ---- Version A: count ----

resource "aws_security_group" "count_demo" {
  name        = "demo-count"
  description = "Rules created with count"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "with_count" {
  count = length(var.rules)

  security_group_id = aws_security_group.count_demo.id
  description       = var.rules[count.index].name
  cidr_ipv4         = "10.0.0.0/8"
  ip_protocol       = "tcp"
  from_port         = var.rules[count.index].port
  to_port           = var.rules[count.index].port
}

# ---- Version B: for_each ----

resource "aws_security_group" "for_each_demo" {
  name        = "demo-for-each"
  description = "Rules created with for_each"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "with_for_each" {
  for_each = { for r in var.rules : r.name => r }

  security_group_id = aws_security_group.for_each_demo.id
  description       = each.value.name
  cidr_ipv4         = "10.0.0.0/8"
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
}
