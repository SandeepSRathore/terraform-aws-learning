variable "name" {
  description = "Name for the Beanstalk application and environment"
  type        = string
}

variable "solution_stack_regex" {
  description = "Picks the platform (OS + language runtime). Newest match wins."
  type        = string
  default     = "^64bit Amazon Linux 2023 (.*) running Python 3(.*)$"
}

variable "instance_type" {
  description = "EC2 size for the environment's instances"
  type        = string
  default     = "t3.micro"
}

variable "environment_type" {
  description = "SingleInstance (cheap, no load balancer) or LoadBalanced"
  type        = string
  default     = "SingleInstance"

  validation {
    condition     = contains(["SingleInstance", "LoadBalanced"], var.environment_type)
    error_message = "environment_type must be SingleInstance or LoadBalanced."
  }
}

variable "vpc_id" {
  description = "VPC to run in"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the instances"
  type        = list(string)
}

variable "env_vars" {
  description = "Environment variables for the application"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Extra tags for every resource in this module"
  type        = map(string)
  default     = {}
}
