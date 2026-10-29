output "bucket_name" {
  value = aws_s3_bucket.this.id
}

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "versioning_status" {
  value = aws_s3_bucket_versioning.this.versioning_configuration[0].status
}
