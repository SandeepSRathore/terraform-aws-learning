#!/usr/bin/env bash
# Read the secret like an app would, then rotate it manually and see versions.
set -euo pipefail
cd "$(dirname "$0")"

S=$(terraform output -raw secret_name)

echo "--- read the secret (what your app does at startup)"
aws secretsmanager get-secret-value --secret-id "$S" --query SecretString --output text |
  python3 -c 'import json,sys; d=json.load(sys.stdin); print("username:", d["username"], "| password:", d["password"][:4] + "*" * 20, "| host:", d["host"])'

echo "--- rotate: put a new value; the old one becomes AWSPREVIOUS"
aws secretsmanager put-secret-value --secret-id "$S" \
  --secret-string '{"username":"app_user","password":"rotated-by-hand","host":"db.internal","port":5432}' \
  --query VersionStages --output text
aws secretsmanager list-secret-version-ids --secret-id "$S" \
  --query 'Versions[].[VersionStages[0], VersionId]' --output text

echo "--- the previous value is still readable (handy during a rollout)"
aws secretsmanager get-secret-value --secret-id "$S" --version-stage AWSPREVIOUS \
  --query SecretString --output text | python3 -c 'import json,sys; print("previous password starts with:", json.load(sys.stdin)["password"][:4])'
