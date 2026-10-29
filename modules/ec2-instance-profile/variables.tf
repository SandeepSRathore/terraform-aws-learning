variable "name" {
  description = "Name for the IAM role and instance profile"
  type        = string
}

variable "policy_statements" {
  description = "What the instance may do, e.g. read one S3 object. Keep them as narrow as possible."
  type = list(object({
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "enable_ssm" {
  description = "Allow AWS Systems Manager Session Manager: a browser/CLI shell with no SSH key or open port 22"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags for the role and profile"
  type        = map(string)
  default     = {}
}
