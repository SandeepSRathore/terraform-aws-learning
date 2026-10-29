variable "name" {
  description = "Name tag for the Elastic IP"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance to attach to. null = allocate the IP but leave it unattached."
  type        = string
  default     = null
}

variable "tags" {
  description = "Extra tags for the Elastic IP"
  type        = map(string)
  default     = {}
}
