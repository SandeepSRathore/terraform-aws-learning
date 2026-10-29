#!/usr/bin/env bash
# Put, get, query (table and index), conditional update, conditional failure.
set -euo pipefail
cd "$(dirname "$0")"

T=$(terraform output -raw table_name)

echo "--- put 1 profile + 2 orders in the same partition"
# DynamoDB JSON: every value says its type ("S" string, "N" number).
aws dynamodb put-item --table-name "$T" --item '{"pk":{"S":"CUSTOMER#1"},"sk":{"S":"PROFILE"},"name":{"S":"Asha"}}'
aws dynamodb put-item --table-name "$T" --item '{"pk":{"S":"CUSTOMER#1"},"sk":{"S":"ORDER#2026-10-01"},"status":{"S":"SHIPPED"},"total":{"N":"40"}}'
aws dynamodb put-item --table-name "$T" --item '{"pk":{"S":"CUSTOMER#1"},"sk":{"S":"ORDER#2026-10-20"},"status":{"S":"PENDING"},"total":{"N":"75"}}'
echo "ok"

echo "--- get-item: exact key lookup"
aws dynamodb get-item --table-name "$T" --key '{"pk":{"S":"CUSTOMER#1"},"sk":{"S":"PROFILE"}}' \
  --query 'Item.name.S' --output text

echo "--- query: this customer's orders only (sort key begins_with)"
aws dynamodb query --table-name "$T" \
  --key-condition-expression 'pk = :pk AND begins_with(sk, :o)' \
  --expression-attribute-values '{":pk":{"S":"CUSTOMER#1"},":o":{"S":"ORDER#"}}' \
  --query 'Items[].[sk.S, status.S, total.N]' --output text

echo "--- query the GSI: every PENDING order (any customer)"
aws dynamodb query --table-name "$T" --index-name by-status \
  --key-condition-expression '#s = :s' \
  --expression-attribute-names '{"#s":"status"}' \
  --expression-attribute-values '{":s":{"S":"PENDING"}}' \
  --query 'Items[].[pk.S, sk.S]' --output text
# ("status" is a reserved word, hence the #s placeholder)

echo "--- conditional update: PENDING -> SHIPPED only if still PENDING"
aws dynamodb update-item --table-name "$T" \
  --key '{"pk":{"S":"CUSTOMER#1"},"sk":{"S":"ORDER#2026-10-20"}}' \
  --update-expression 'SET #s = :new' --condition-expression '#s = :old' \
  --expression-attribute-names '{"#s":"status"}' \
  --expression-attribute-values '{":new":{"S":"SHIPPED"},":old":{"S":"PENDING"}}' \
  --return-values UPDATED_NEW --query 'Attributes.status.S' --output text

echo "--- same update again: the condition now fails (optimistic locking)"
aws dynamodb update-item --table-name "$T" \
  --key '{"pk":{"S":"CUSTOMER#1"},"sk":{"S":"ORDER#2026-10-20"}}' \
  --update-expression 'SET #s = :new' --condition-expression '#s = :old' \
  --expression-attribute-names '{"#s":"status"}' \
  --expression-attribute-values '{":new":{"S":"SHIPPED"},":old":{"S":"PENDING"}}' 2>&1 |
  grep -o 'ConditionalCheckFailedException' || true
