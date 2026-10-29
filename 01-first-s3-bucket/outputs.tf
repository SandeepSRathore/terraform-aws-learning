# Outputs print useful values after `terraform apply`.
# They read attributes AWS assigned when it created the resource.

output "bucket_name" {
  description = "The full bucket name AWS generated"
  value       = aws_s3_bucket.learning.bucket
}

output "bucket_arn" {
  description = "Amazon Resource Name (a unique ID for the bucket)"
  value       = aws_s3_bucket.learning.arn
}
