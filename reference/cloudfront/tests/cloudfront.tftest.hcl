mock_provider "aws" {
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn                         = "arn:aws:s3:::demo-site-mock"
      bucket_regional_domain_name = "demo-site-mock.s3.us-east-1.amazonaws.com"
    }
  }

  mock_resource "aws_cloudfront_distribution" {
    defaults = {
      arn = "arn:aws:cloudfront::123456789012:distribution/EMOCK"
    }
  }
}

run "private_bucket_behind_cdn" {
  command = apply

  assert {
    condition     = aws_cloudfront_distribution.site.default_cache_behavior[0].viewer_protocol_policy == "redirect-to-https"
    error_message = "Viewers should be redirected to HTTPS"
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.site.policy).Statement[0].Condition.StringEquals["AWS:SourceArn"] == aws_cloudfront_distribution.site.arn
    error_message = "Only this distribution may read the bucket"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.site.restrict_public_buckets
    error_message = "The bucket must stay private"
  }
}
