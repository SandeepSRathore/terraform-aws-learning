variable "name" {
  description = "Name tag for the volume"
  type        = string
}

variable "availability_zone" {
  description = "Must match the AZ of the instance it will attach to"
  type        = string
}

variable "size" {
  description = "Size in GB"
  type        = number
  default     = 1

  validation {
    condition     = var.size >= 1 && var.size <= 100
    error_message = "size must be 1-100 GB for this learning module."
  }
}

variable "type" {
  description = "Volume type"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3"], var.type)
    error_message = "type must be gp2 or gp3."
  }
}

# Why a separate bool instead of "attach if instance_id != null"?
# `count` must be known at PLAN time, but an instance ID doesn't exist until
# the instance is created. A plain true/false is always known up front.
variable "attach" {
  description = "Attach the volume to instance_id"
  type        = bool
  default     = false
}

variable "instance_id" {
  description = "Instance to attach to (used when attach = true)"
  type        = string
  default     = null
}

variable "device_name" {
  description = "Device name. On modern instances it appears in Linux as /dev/nvme1n1."
  type        = string
  default     = "/dev/sdf"
}

variable "tags" {
  description = "Extra tags for the volume"
  type        = map(string)
  default     = {}
}
