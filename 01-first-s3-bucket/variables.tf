# Input variables are like function parameters for your configuration.
# Override defaults with: terraform apply -var="aws_region=eu-west-1"
# or by putting values in a terraform.tfvars file.

variable "aws_region" {
  description = "AWS region to create resources in"
  type        = string
  default     = "us-east-1"
}

variable "bucket_prefix" {
  description = "Start of the S3 bucket name; AWS appends a unique suffix"
  type        = string
  default     = "tf-learning-"
}
