variable "name" {
  description = "Security group name"
  type        = string
}

variable "description" {
  description = "What this security group is for"
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "VPC the security group belongs to"
  type        = string
}

# A map of objects: the key (e.g. "http") becomes the rule's name in state.
# optional() lets callers leave out fields that have sensible defaults.
variable "ingress_rules" {
  description = "Inbound rules, keyed by a short name"
  type = map(object({
    description = string
    port        = number
    cidr_ipv4   = string
    protocol    = optional(string, "tcp")
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.ingress_rules) : r.port >= 1 && r.port <= 65535])
    error_message = "Every port must be between 1 and 65535."
  }

  validation {
    condition = !anytrue([
      for r in values(var.ingress_rules) : r.port == 22 && r.cidr_ipv4 == "0.0.0.0/0"
    ])
    error_message = "Don't open SSH (22) to the whole internet. Use your own IP, e.g. 203.0.113.10/32."
  }
}

variable "allow_all_egress" {
  description = "Allow all outbound traffic (needed to download packages, pull images)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags for the security group"
  type        = map(string)
  default     = {}
}
