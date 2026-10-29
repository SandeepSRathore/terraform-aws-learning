variable "aws_region" {
  description = "AWS region for this environment"
  type        = string
  default     = "us-east-1"
}

# ---- LocalStack: a pretend AWS running in Docker on your laptop ----

variable "use_localstack" {
  description = "Send every AWS API call to LocalStack instead of real AWS"
  type        = bool
  default     = false
}

variable "localstack_endpoint" {
  description = "URL LocalStack listens on (4566 is its default port)"
  type        = string
  default     = "http://localhost:4566"
}

variable "project" {
  description = "Short project name, used as a prefix for resource names"
  type        = string
  default     = "tf-learning"
}

# ---- Feature toggles: switch each service on or off ----

variable "enable_s3" {
  description = "Create the S3 assets bucket"
  type        = bool
  default     = true
}

variable "enable_ec2" {
  description = "Create the EC2 web server and its security group"
  type        = bool
  default     = true
}

variable "enable_elastic_ip" {
  description = "Give the EC2 web server a fixed public IP (requires enable_ec2)"
  type        = bool
  default     = false
}

variable "enable_ebs" {
  description = "Attach an extra data volume to the EC2 web server (requires enable_ec2)"
  type        = bool
  default     = false
}

variable "enable_ecs" {
  description = "Run an nginx container on ECS Fargate"
  type        = bool
  default     = false
}

variable "enable_beanstalk" {
  description = "Create an Elastic Beanstalk Python environment"
  type        = bool
  default     = false
}

variable "enable_lambda" {
  description = "Run a Lambda on every upload to uploads/ in the S3 bucket (requires enable_s3)"
  type        = bool
  default     = false
}

# ---- EC2 settings ----

variable "ssh_cidr" {
  description = "Your IP as a /32 CIDR to allow SSH, e.g. 203.0.113.10/32. null = no SSH."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Existing EC2 key pair name for SSH. null = no key."
  type        = string
  default     = null
}

variable "web_message" {
  description = "Text shown on the EC2 web page"
  type        = string
  default     = "Hello from Terraform modules!"
}

# ---- Spring Boot on EC2 ----

variable "enable_springboot" {
  description = "Deploy the Spring Boot JAR from apps/hello-springboot to its own EC2 instance"
  type        = bool
  default     = false
}

variable "springboot_jar_path" {
  description = "JAR to deploy. null = apps/hello-springboot/target/hello-springboot.jar"
  type        = string
  default     = null
}

variable "springboot_message" {
  description = "Passed to the app as APP_MESSAGE; shown by GET /"
  type        = string
  default     = "Hello from Spring Boot on EC2!"
}
