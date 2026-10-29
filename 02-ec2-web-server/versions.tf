# New in this lesson: more than one provider.
#   aws   -> creates the EC2 instance, security group, volumes, IPs
#   tls   -> generates an SSH key pair locally (no cloud involved)
#   local -> writes the private key to a file on your Mac
#   http  -> looks up your public IP so SSH is only open to you
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "terraform-learning"
      ManagedBy = "terraform"
      Lesson    = "02"
    }
  }
}
