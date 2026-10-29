#!/usr/bin/env bash
# Proves a reference example works end to end on LocalStack:
#   terraform apply -> ./exercise.sh -> terraform destroy
# The exercise output is saved to <example>/exercise-output.txt as a record.
#
# Usage: ./reference/verify.sh sqs           (one example)
#        ./reference/verify.sh sqs --keep    (leave the resources running)
set -euo pipefail

REF="$(cd "$(dirname "$0")" && pwd)"
name="${1:?usage: verify.sh <example> [--keep]}"
keep="${2:-}"
dir="$REF/$name"

# shellcheck source=/dev/null
source "$REF/localstack.env"
cd "$dir"

curl -sf -o /dev/null "$AWS_ENDPOINT_URL/_localstack/health" || {
  echo "LocalStack is not running: lstk start --non-interactive" >&2
  exit 1
}

# Always clean up, even when the exercise fails (unless --keep).
cleanup() {
  if [ "$keep" != "--keep" ]; then
    echo "=== destroy"
    terraform destroy -auto-approve -input=false -no-color | tail -1
  fi
}
trap cleanup EXIT

echo "=== apply ($name)"
terraform init -input=false -no-color >/dev/null
terraform apply -auto-approve -input=false -no-color | grep -E '^Apply complete'

echo "=== exercise"
{
  echo "# Output of exercise.sh on LocalStack $(curl -s "$AWS_ENDPOINT_URL/_localstack/info" | sed -E 's/.*"version": "([^"]+)".*/\1/'), $(date +%Y-%m-%d)"
  ./exercise.sh
} 2>&1 | tee exercise-output.txt
