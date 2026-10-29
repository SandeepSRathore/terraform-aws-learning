#!/usr/bin/env bash
# Hit the load balancer and watch listener rules pick the response.
set -euo pipefail
cd "$(dirname "$0")"

DNS=$(terraform output -raw dns_name)
# Real AWS: http://$DNS. LocalStack serves every load balancer on its own port.
BASE="http://$DNS"
[ -n "${AWS_ENDPOINT_URL:-}" ] && BASE="http://$DNS:4566"
echo "ALB: $BASE"

for path in /health /anything-else; do
  echo "--- GET $path"
  curl -s -w "  (HTTP %{http_code})\n" "$BASE$path"
done

echo "--- target group health (empty: no targets registered yet)"
aws elbv2 describe-target-health --target-group-arn "$(terraform output -raw target_group_arn)" \
  --query 'length(TargetHealthDescriptions)' --output text | sed 's/^/registered targets: /'

echo "--- rules in priority order"
aws elbv2 describe-rules --listener-arn "$(aws elbv2 describe-listeners --load-balancer-arn \
  "$(aws elbv2 describe-load-balancers --names demo-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)" \
  --query 'Listeners[0].ListenerArn' --output text)" \
  --query 'Rules[].[Priority, Conditions[0].Values[0] || `-`, Actions[0].Type]' --output text
