variable "name" {
  description = "Name tag for the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 size. t3.micro is Free Tier eligible in most regions."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Image to boot. null = latest Amazon Linux 2023."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet to launch into (decides the VPC and availability zone)"
  type        = string
}

variable "security_group_ids" {
  description = "Security groups (firewalls) to attach"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Existing EC2 key pair name for SSH. null = no SSH key."
  type        = string
  default     = null
}

variable "user_data" {
  description = "Script run once on first boot"
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "Instance profile NAME giving the instance an IAM role (e.g. to read S3). null = no role."
  type        = string
  default     = null
}

variable "associate_public_ip" {
  description = "Give the instance a public IP so it is reachable from the internet"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 100
    error_message = "root_volume_size must be 8-100 GB (Amazon Linux needs at least 8)."
  }
}

variable "tags" {
  description = "Extra tags for the instance"
  type        = map(string)
  default     = {}
}
