variable "aws_region" {
  description = "AWS region to create resources in"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name used for the instance and related resources"
  type        = string
  default     = "tf-learning-web"
}

variable "instance_type" {
  description = "EC2 size. t3.micro is Free Tier eligible in most regions."
  type        = string
  default     = "t3.micro"

  # Validation rules reject bad input before anything reaches AWS.
  validation {
    condition     = can(regex("^t3\\.", var.instance_type))
    error_message = "For this lesson, stick to the cheap t3 family (e.g. t3.micro, t3.small)."
  }
}

variable "web_message" {
  description = "Text shown on the web page served by the instance"
  type        = string
  default     = "Hello from Terraform!"
}

# ---- Feature toggles: flip these one at a time to test each scenario ----

variable "enable_extra_volume" {
  description = "Scenario 5: create and attach an extra EBS data volume"
  type        = bool
  default     = false
}

variable "enable_elastic_ip" {
  description = "Scenario 6: give the instance a fixed public IP (Elastic IP)"
  type        = bool
  default     = false
}
