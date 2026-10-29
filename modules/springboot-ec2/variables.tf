variable "name" {
  description = "App name: used for the Linux user, /opt/<name>, the systemd service and AWS resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.name))
    error_message = "name must be 2-31 chars: lowercase letters, digits and hyphens, starting with a letter."
  }
}

# ---- The artifact ----

variable "jar_path" {
  description = "Local path to the Spring Boot fat JAR (e.g. target/app.jar). Build it before plan/apply."
  type        = string
}

variable "artifact_bucket" {
  description = "Existing S3 bucket the JAR is uploaded to; the instance downloads it from there"
  type        = string
}

variable "artifact_prefix" {
  description = "Folder inside the bucket for this app's artifacts"
  type        = string
  default     = "artifacts"
}

# ---- Where it runs ----

variable "vpc_id" {
  description = "VPC for the security group"
  type        = string
}

variable "subnet_id" {
  description = "Subnet to launch the instance into (public, so the app is reachable)"
  type        = string
}

variable "instance_type" {
  description = "EC2 size. t3.micro (1 GB) is enough for a small app with jvm_opts capped at 512 MB."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Image to boot. null = latest Amazon Linux 2023 (the scripts expect AL2023: dnf, Corretto)."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Existing EC2 key pair for SSH. null = no key (use Session Manager instead)."
  type        = string
  default     = null
}

# ---- The app ----

variable "java_version" {
  description = "Amazon Corretto major version to install. Must be >= the version the JAR was compiled for."
  type        = number
  default     = 21

  validation {
    condition     = contains([17, 21, 25], var.java_version)
    error_message = "java_version must be an LTS release Amazon Linux 2023 packages: 17, 21 or 25."
  }
}

variable "jvm_opts" {
  description = "JVM flags. Cap the heap so the JVM fits the instance's memory."
  type        = string
  default     = "-Xms256m -Xmx512m"
}

variable "app_port" {
  description = "Port the app listens on (passed to Spring Boot as SERVER_PORT)"
  type        = number
  default     = 8080

  validation {
    # Ports below 1024 need root, and the app deliberately runs as a normal user.
    condition     = var.app_port >= 1024 && var.app_port <= 65535
    error_message = "app_port must be 1024-65535 (the app does not run as root)."
  }
}

variable "app_env" {
  description = <<-EOT
    Environment variables for the app, e.g. { SPRING_PROFILES_ACTIVE = "dev" }.
    They end up in user_data, which anyone with ec2:DescribeInstanceAttribute can read,
    so never put secrets here: read those from Secrets Manager or SSM at runtime.
  EOT
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k in keys(var.app_env) : can(regex("^[A-Z_][A-Z0-9_]*$", k))])
    error_message = "app_env keys must be UPPER_SNAKE_CASE, like SPRING_PROFILES_ACTIVE."
  }

  validation {
    # The env file is read by systemd AND by bash, so keep values to plain text.
    condition     = alltrue([for v in values(var.app_env) : !can(regex("[\"\\\\$`\n]", v))])
    error_message = "app_env values must not contain \", \\, $, backticks or newlines."
  }
}

variable "health_check_path" {
  description = "HTTP path that returns 200 when the app is ready"
  type        = string
  default     = "/actuator/health"
}

variable "health_check_timeout" {
  description = "Seconds the bootstrap script waits for the app to become healthy"
  type        = number
  default     = 180
}

# ---- Network access ----

variable "allowed_cidrs" {
  description = "Who may reach app_port"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_cidr" {
  description = "Your IP as a /32 to allow SSH. null = port 22 stays closed."
  type        = string
  default     = null
}

# ---- LocalStack only ----

variable "aws_endpoint_url" {
  description = "Only for LocalStack: where the instance's AWS CLI sends S3 calls. null = real AWS."
  type        = string
  default     = null
}

variable "tags" {
  description = "Extra tags for every resource in this module"
  type        = map(string)
  default     = {}
}
