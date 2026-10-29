#!/usr/bin/env bash
# Inspect the issued certificate and the DNS record that validated it.
set -euo pipefail
cd "$(dirname "$0")"

ARN=$(terraform output -raw certificate_arn)

echo "--- certificate"
aws acm describe-certificate --certificate-arn "$ARN" \
  --query 'Certificate.{Domain: DomainName, AlsoCovers: SubjectAlternativeNames, Status: Status, Type: Type, Renewal: RenewalEligibility}' --output yaml

echo "--- the DNS record ACM asked for (now in Route 53)"
aws acm describe-certificate --certificate-arn "$ARN" \
  --query 'Certificate.DomainValidationOptions[].[DomainName, ValidationStatus, ResourceRecord.Name, ResourceRecord.Type]' --output text
