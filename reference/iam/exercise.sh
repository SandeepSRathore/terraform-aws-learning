#!/usr/bin/env bash
# Check what alice may do, act as alice, then assume the deployer role.
set -euo pipefail
cd "$(dirname "$0")"

ALICE=$(terraform output -raw alice_arn)
ROLE=$(terraform output -raw deployer_role_arn)

echo "--- policy simulator: is alice allowed? (via her group's policy)"
aws iam simulate-principal-policy --policy-source-arn "$ALICE" \
  --action-names s3:GetObject s3:DeleteObject \
  --resource-arns arn:aws:s3:::company-reports/q3.pdf \
  --query 'EvaluationResults[].[EvalActionName, EvalDecision]' --output text

echo "--- who am I, using alice's own access keys?"
export AWS_ACCESS_KEY_ID=$(terraform output -raw alice_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(terraform output -raw alice_secret_access_key)
aws sts get-caller-identity --query Arn --output text

echo "--- alice assumes the deployer role and gets TEMPORARY credentials"
CREDS=$(aws sts assume-role --role-arn "$ROLE" --role-session-name alice-deploy --duration-seconds 900 --output json)
echo "$CREDS" | python3 -c 'import json,sys; c=json.load(sys.stdin)["Credentials"]; print("temp key:", c["AccessKeyId"][:8] + "...", "| expires:", c["Expiration"])'

export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | python3 -c 'import json,sys; print(json.load(sys.stdin)["Credentials"]["AccessKeyId"])')
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | python3 -c 'import json,sys; print(json.load(sys.stdin)["Credentials"]["SecretAccessKey"])')
export AWS_SESSION_TOKEN=$(echo "$CREDS" | python3 -c 'import json,sys; print(json.load(sys.stdin)["Credentials"]["SessionToken"])')
echo "--- who am I now?"
aws sts get-caller-identity --query Arn --output text
