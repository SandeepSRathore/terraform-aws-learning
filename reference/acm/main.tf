# ACM = free TLS (HTTPS) certificates for AWS services: ALB, CloudFront, API
# Gateway. AWS renews them automatically. (You can't download the private key,
# so they only work on those AWS services.)
#
# To prove you own the domain, ACM asks for a DNS record. With the zone in
# Route 53, Terraform can create that record itself and wait until the
# certificate is ISSUED: the 3-resource pattern below.
#
# CloudFront only accepts certificates from us-east-1, whatever region the rest
# of your stack is in (use a second provider block with an alias for that).

resource "aws_route53_zone" "main" {
  name = "example-shop.com"
}

resource "aws_acm_certificate" "site" {
  domain_name               = "example-shop.com"
  subject_alternative_names = ["*.example-shop.com"] # wildcard covers www, api, ...
  validation_method         = "DNS"

  # Replacing a cert in use: create the new one before deleting the old one.
  lifecycle {
    create_before_destroy = true
  }
}

# One entry per domain on the certificate. Keyed by domain_name because it is
# known at PLAN time; the record name/value only exist after the certificate
# is created, and for_each keys must be known up front.
resource "aws_route53_record" "validation" {
  for_each = {
    for o in aws_acm_certificate.site.domain_validation_options : o.domain_name => o
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60

  # The apex and the wildcard ask for the SAME record; without this the
  # second one would fail with "record already exists".
  allow_overwrite = true
}

# Not a real AWS object: it makes `apply` wait until ACM reports ISSUED,
# so anything using the certificate (an HTTPS listener) only runs after that.
resource "aws_acm_certificate_validation" "site" {
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}
