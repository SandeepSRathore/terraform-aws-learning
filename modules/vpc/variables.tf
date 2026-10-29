variable "name" {
  description = "Name prefix for the VPC and everything inside it"
  type        = string
}

variable "cidr_block" {
  description = "IP range for the whole VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid CIDR, e.g. 10.0.0.0/16."
  }
}

variable "public_subnet_count" {
  description = "How many public subnets to create, one per availability zone"
  type        = number
  default     = 2

  validation {
    condition     = var.public_subnet_count >= 1 && var.public_subnet_count <= 4
    error_message = "public_subnet_count must be between 1 and 4."
  }
}

variable "tags" {
  description = "Extra tags for every resource in this module"
  type        = map(string)
  default     = {}
}
