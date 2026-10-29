mock_provider "aws" {
  # The real provider knows domain_validation_options' domain names at plan
  # time; a mock doesn't, unless its values are applied during plan too
  # (override_during, Terraform 1.11+).
  mock_resource "aws_acm_certificate" {
    override_during = plan
    defaults = {
      arn = "arn:aws:acm:us-east-1:123456789012:certificate/mock"
      domain_validation_options = [
        { domain_name = "example-shop.com", resource_record_name = "_x.example-shop.com.", resource_record_type = "CNAME", resource_record_value = "_y.acm-validations.aws." },
        { domain_name = "*.example-shop.com", resource_record_name = "_x.example-shop.com.", resource_record_type = "CNAME", resource_record_value = "_y.acm-validations.aws." },
      ]
    }
  }
}

run "dns_validation" {
  command = plan

  assert {
    condition     = aws_acm_certificate.site.validation_method == "DNS"
    error_message = "Certificate should validate via DNS"
  }

  assert {
    condition     = toset(keys(aws_route53_record.validation)) == toset(["example-shop.com", "*.example-shop.com"])
    error_message = "Expected one validation entry per domain on the certificate"
  }

  assert {
    condition     = alltrue([for r in aws_route53_record.validation : r.allow_overwrite])
    error_message = "Apex and wildcard share a record name, so overwriting must be allowed"
  }
}
