# CloudFront = AWS's CDN. It caches your content in 400+ edge locations near
# users, adds HTTPS, and shields the origin (S3, ALB, API Gateway) from load.
#
# The standard static-website setup shown here:
#   private S3 bucket  <--only CloudFront may read--  distribution  <--  users
# Origin Access Control (OAC) signs CloudFront's requests to S3, and the bucket
# policy allows only this distribution, so the bucket itself stays private.

resource "aws_s3_bucket" "site" {
  bucket_prefix = "demo-site-"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "demo-site-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  comment             = "Demo static site"
  default_root_object = "index.html"     # what / serves
  price_class         = "PriceClass_100" # cheapest: North America + Europe edges only

  origin {
    origin_id                = "s3-site"
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-site"
    viewer_protocol_policy = "redirect-to-https" # http:// requests get a 301 to https://
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # AWS-managed cache policy "CachingOptimized" (same ID in every account).
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # Single-page apps: send unknown paths to index.html instead of a 404.
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" # or "whitelist"/"blacklist" with country codes
    }
  }

  # *.cloudfront.net certificate. For your own domain: aliases = ["www.example.com"]
  # plus acm_certificate_arn (from us-east-1) and ssl_support_method = "sni-only".
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Only this distribution may read objects from the bucket.
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
      Condition = { StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.site.arn } }
    }]
  })
}
