output "certificate_arn" {
  # Referencing the validation resource means "an ISSUED certificate".
  value = aws_acm_certificate_validation.site.certificate_arn
}
