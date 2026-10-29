#!/usr/bin/env bash
# Upload a page to the private bucket and fetch it through CloudFront.
set -euo pipefail
cd "$(dirname "$0")"

DOMAIN=$(terraform output -raw distribution_domain)
DIST=$(terraform output -raw distribution_id)
BUCKET=$(terraform output -raw bucket)
# Real AWS: https://<id>.cloudfront.net. LocalStack serves it on port 4566.
BASE="https://$DOMAIN"
[ -n "${AWS_ENDPOINT_URL:-}" ] && BASE="http://$DOMAIN:4566"

echo "--- upload index.html to the (private) bucket"
echo '<h1>Hello from CloudFront</h1>' | aws s3 cp - "s3://$BUCKET/index.html" --content-type text/html

echo "--- fetch / through the CDN ($BASE)"
curl -s -w '  (HTTP %{http_code})\n' "$BASE/"

echo "--- unknown path: the custom error response serves index.html (SPA routing)"
curl -s -w '  (HTTP %{http_code})\n' "$BASE/some/client/route"

echo "--- after a deploy, clear the edge caches (first 1,000 paths/month are free)"
aws cloudfront create-invalidation --distribution-id "$DIST" --paths '/*' \
  --query 'Invalidation.Status' --output text | sed 's/^/invalidation: /'
