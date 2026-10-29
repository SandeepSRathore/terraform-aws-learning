output "distribution_domain" {
  value = aws_cloudfront_distribution.site.domain_name # xxxx.cloudfront.net
}

output "distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

output "bucket" {
  value = aws_s3_bucket.site.id
}
