# This is a ROOT module: the folder you actually run `terraform apply` in.
# Unlike the reusable modules, it configures the provider (region, tags).
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # ---- LocalStack (only when use_localstack = true) ----
  # LocalStack accepts any credentials; "test" is the convention.
  # null means "not set", so against real AWS your normal credentials are used.
  access_key = var.use_localstack ? "test" : null
  secret_key = var.use_localstack ? "test" : null

  # These checks call real AWS, which would reject the fake credentials.
  skip_credentials_validation = var.use_localstack
  skip_requesting_account_id  = var.use_localstack

  # http://localhost:4566/<bucket> instead of http://<bucket>.localhost:4566
  s3_use_path_style = var.use_localstack

  # `dynamic` makes this block appear 0 or 1 times, the way count does for
  # resources. Each line redirects one AWS service used by the modules.
  dynamic "endpoints" {
    for_each = var.use_localstack ? [var.localstack_endpoint] : []
    content {
      ec2              = endpoints.value
      ecs              = endpoints.value
      elasticbeanstalk = endpoints.value
      iam              = endpoints.value
      lambda           = endpoints.value
      logs             = endpoints.value
      s3               = endpoints.value
      sts              = endpoints.value
    }
  }

  default_tags {
    tags = {
      Project     = var.project
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
