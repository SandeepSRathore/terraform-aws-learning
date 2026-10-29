variable "name" {
  description = "Name for the cluster, service, task family and log group"
  type        = string
}

variable "container_image" {
  description = "Docker image to run"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

# Fargate only accepts specific cpu/memory pairs, e.g.
#   256 (.25 vCPU) -> 512, 1024, 2048 MB
#   512 (.5 vCPU)  -> 1024 - 4096 MB
variable "cpu" {
  description = "CPU units for the task (1024 = 1 vCPU)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "cpu must be one of 256, 512, 1024, 2048, 4096."
  }
}

variable "memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "How many copies of the task to keep running"
  type        = number
  default     = 1
}

variable "environment" {
  description = "Environment variables passed to the container"
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "Subnets the tasks run in"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups for the tasks"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Needed in public subnets so tasks can pull images from the internet"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "How long CloudWatch keeps container logs"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Extra tags for every resource in this module"
  type        = map(string)
  default     = {}
}
