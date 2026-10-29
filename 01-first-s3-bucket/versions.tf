# Which Terraform version and which providers this project needs.
# A "provider" is a plugin that knows how to talk to one platform's API (here: AWS).
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # any 6.x release, but not 7.0
    }
  }
}

# Configure the AWS provider. Credentials come from your AWS CLI setup
# (~/.aws/credentials), never hard-code them here.
provider "aws" {
  region = var.aws_region

  # Tags added automatically to every resource this provider creates.
  default_tags {
    tags = {
      Project   = "terraform-learning"
      ManagedBy = "terraform"
    }
  }
}
