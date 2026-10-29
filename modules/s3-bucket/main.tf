# In AWS provider v4+, a bucket's settings are separate resources that
# point at the bucket. This keeps each concern small and independent.

resource "aws_s3_bucket" "this" {
  bucket_prefix = var.bucket_prefix
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Belt and braces: block every way of making this bucket public.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Only created when expiration_days is set.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.expiration_days == null ? 0 : 1

  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-objects"
    status = "Enabled"

    filter {} # empty filter = applies to every object

    expiration {
      days = var.expiration_days
    }
  }
}
