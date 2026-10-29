#!/usr/bin/env bash
# Read one parameter, read a whole path, and see SecureString with/without decryption.
set -euo pipefail
cd "$(dirname "$0")"

P=$(terraform output -raw prefix)

echo "--- one parameter"
aws ssm get-parameter --name "$P/log_level" --query Parameter.Value --output text

# Real AWS returns opaque base64 ciphertext here. LocalStack only fakes it
# ("kms:<key>:<plaintext>"), so don't rely on that output format.
echo "--- SecureString without --with-decryption: you get ciphertext"
aws ssm get-parameter --name "$P/api_key" --query Parameter.Value --output text | cut -c1-40

echo "--- the whole path at once, decrypted (what an app does at startup)"
aws ssm get-parameters-by-path --path "$P" --recursive --with-decryption \
  --query 'Parameters[].[Name, Type, Value]' --output text

echo "--- change a value: every change creates a new version"
aws ssm put-parameter --name "$P/log_level" --value debug --type String --overwrite --query Version --output text | sed 's/^/new version: /'
aws ssm get-parameter-history --name "$P/log_level" --query 'Parameters[].[Version, Value]' --output text
