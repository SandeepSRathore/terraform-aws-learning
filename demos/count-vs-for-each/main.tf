# Demo: why the security-group module uses for_each instead of count.
#
# terraform_data is built into Terraform: it stores a value in state and
# creates nothing anywhere. No provider, no account, no mocks.
# Each copy stands in for one firewall rule.
#
#   terraform init
#   terraform apply -auto-approve                       # create 3 "rules"
#   terraform plan -var-file=remove-http.tfvars         # remove the first one

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

# Version A: count. Each copy is identified by its POSITION: [0], [1], [2].
resource "terraform_data" "with_count" {
  count = length(var.rules)

  input = var.rules[count.index]
}

# Version B: for_each. Each copy is identified by its KEY: ["http"], ["https"], ...
# The for expression turns the list into a map keyed by name.
resource "terraform_data" "with_for_each" {
  for_each = { for r in var.rules : r.name => r }

  input = each.value
}
