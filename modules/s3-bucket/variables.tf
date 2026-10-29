variable "bucket_prefix" {
  description = "Start of the bucket name; AWS appends a unique suffix"
  type        = string

  validation {
    # AWS limit for a prefix is 37 chars; bucket names are lowercase only.
    condition     = length(var.bucket_prefix) <= 37 && can(regex("^[a-z0-9][a-z0-9.-]*$", var.bucket_prefix))
    error_message = "bucket_prefix must be lowercase letters, numbers, dots or hyphens, max 37 chars."
  }
}

variable "enable_versioning" {
  description = "Keep old versions of objects when they are overwritten or deleted"
  type        = bool
  default     = true
}

variable "expiration_days" {
  description = "Delete objects automatically after this many days. null = keep forever."
  type        = number
  default     = null
}

variable "force_destroy" {
  description = "Allow destroying the bucket even when it still contains objects"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags for the bucket"
  type        = map(string)
  default     = {}
}
