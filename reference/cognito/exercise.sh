#!/usr/bin/env bash
# Create a user as an admin, log in, look inside the token, try a bad password.
set -euo pipefail
cd "$(dirname "$0")"

POOL=$(terraform output -raw user_pool_id)
CLIENT=$(terraform output -raw client_id)
EMAIL=asha@example.com

echo "--- admin creates a user (SUPPRESS = don't send the welcome email)"
aws cognito-idp admin-create-user --user-pool-id "$POOL" --username "$EMAIL" \
  --user-attributes Name=email,Value="$EMAIL" Name=email_verified,Value=true Name=custom:plan,Value=pro \
  --message-action SUPPRESS --query 'User.UserStatus' --output text
# New users must change their temporary password; an admin can set a permanent one.
aws cognito-idp admin-set-user-password --user-pool-id "$POOL" --username "$EMAIL" \
  --password 'Correct-Horse-42' --permanent
echo "password set (status CONFIRMED)"

echo "--- the user logs in and gets 3 tokens"
TOKENS=$(aws cognito-idp initiate-auth --client-id "$CLIENT" --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME="$EMAIL",PASSWORD='Correct-Horse-42' --output json)
echo "$TOKENS" | python3 -c 'import json,sys; r=json.load(sys.stdin)["AuthenticationResult"]; print("got:", ", ".join(k for k in r if k.endswith("Token")), "| expires in", r["ExpiresIn"], "s")'

echo "--- inside the id token (a JWT: header.payload.signature, payload is base64 JSON)"
echo "$TOKENS" | python3 -c '
import json, sys, base64
tok = json.load(sys.stdin)["AuthenticationResult"]["IdToken"]
payload = tok.split(".")[1]
claims = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
for k in ("email", "custom:plan", "token_use", "iss"):
    print(f"  {k}: {claims.get(k)}")'

echo "--- wrong password"
aws cognito-idp initiate-auth --client-id "$CLIENT" --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME="$EMAIL",PASSWORD='wrong-password' 2>&1 | grep -oE 'NotAuthorizedException[^.]*' || true
