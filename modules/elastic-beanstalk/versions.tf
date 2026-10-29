# Modules declare WHICH providers they need, but never configure them
# (no region, no credentials). The caller's provider "aws" block is used.
terraform {
  required_version = ">= 1.7.0" # 1.7+ is needed for mock providers in tests

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
