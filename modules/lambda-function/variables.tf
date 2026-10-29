variable "name" {
  description = "Function name; also used for its IAM role and log group"
  type        = string
}

variable "source_dir" {
  description = "Folder with the function's code; it is zipped and uploaded"
  type        = string
}

variable "handler" {
  description = "<file without .py>.<function name> that Lambda calls"
  type        = string
  default     = "handler.handler"
}

variable "runtime" {
  description = "Language runtime Lambda runs the code with"
  type        = string
  default     = "python3.13"
}

variable "timeout" {
  description = "Seconds a single run may take before Lambda stops it"
  type        = number
  default     = 10

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900 seconds (Lambda's 15 minute limit)."
  }
}

variable "memory_size" {
  description = "Memory in MB; CPU power scales with it"
  type        = number
  default     = 128

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240 MB."
  }
}

variable "environment" {
  description = "Environment variables, readable in code with os.environ"
  type        = map(string)
  default     = {}
}

variable "policy_statements" {
  description = "Extra permissions, e.g. reading one S3 folder. Keep them as narrow as possible."
  type = list(object({
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "log_retention_days" {
  description = "How long CloudWatch keeps the function's logs"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Extra tags for every resource in this module"
  type        = map(string)
  default     = {}
}
