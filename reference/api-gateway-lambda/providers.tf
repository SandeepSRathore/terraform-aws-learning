# Identical in every reference example, so each folder works on its own when
# copied. With use_localstack = true, every AWS service below goes to LocalStack
# (`source ../localstack.env` sets it); otherwise it's real AWS.
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = { # only this example: zips the Lambda code
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}

variable "use_localstack" {
  description = "Send every AWS API call to LocalStack instead of real AWS"
  type        = bool
  default     = false
}

variable "localstack_endpoint" {
  description = "URL LocalStack listens on"
  type        = string
  default     = "http://localhost:4566"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

provider "aws" {
  region = var.aws_region

  access_key                  = var.use_localstack ? "test" : null
  secret_key                  = var.use_localstack ? "test" : null
  skip_credentials_validation = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  s3_use_path_style           = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [var.localstack_endpoint] : []
    content {
      acm            = endpoints.value
      apigateway     = endpoints.value
      apigatewayv2   = endpoints.value
      autoscaling    = endpoints.value
      cloudfront     = endpoints.value
      cloudwatch     = endpoints.value
      cognitoidp     = endpoints.value
      dynamodb       = endpoints.value
      ec2            = endpoints.value
      ecr            = endpoints.value
      elasticache    = endpoints.value
      elbv2          = endpoints.value
      events         = endpoints.value
      iam            = endpoints.value
      kinesis        = endpoints.value
      kms            = endpoints.value
      lambda         = endpoints.value
      logs           = endpoints.value
      rds            = endpoints.value
      route53        = endpoints.value
      s3             = endpoints.value
      secretsmanager = endpoints.value
      sfn            = endpoints.value
      sns            = endpoints.value
      sqs            = endpoints.value
      ssm            = endpoints.value
      sts            = endpoints.value
    }
  }

  default_tags {
    tags = {
      Project   = "tf-reference"
      ManagedBy = "terraform"
    }
  }
}
