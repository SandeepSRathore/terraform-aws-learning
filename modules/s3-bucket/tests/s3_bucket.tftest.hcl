mock_provider "aws" {}

variables {
  bucket_prefix = "tf-learning-"
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = output.versioning_status == "Enabled"
    error_message = "Versioning should be on by default"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls && aws_s3_bucket_public_access_block.this.restrict_public_buckets
    error_message = "Public access must be blocked"
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this) == 0
    error_message = "No lifecycle rule unless expiration_days is set"
  }
}

run "expiration_rule_when_requested" {
  command = plan

  variables {
    expiration_days   = 7
    enable_versioning = false
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.this[0].rule[0].expiration[0].days == 7
    error_message = "Objects should expire after 7 days"
  }

  assert {
    condition     = output.versioning_status == "Suspended"
    error_message = "Versioning should be suspended when disabled"
  }
}

run "rejects_uppercase_names" {
  command = plan

  variables {
    bucket_prefix = "My_Bucket"
  }

  expect_failures = [var.bucket_prefix]
}
