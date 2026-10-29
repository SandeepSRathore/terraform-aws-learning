#!/usr/bin/env bash
# Send, receive and delete; watch a failing message land in the DLQ; FIFO order.
# Works against real AWS too (skip `source ../localstack.env`).
set -euo pipefail
cd "$(dirname "$0")"

Q=$(terraform output -raw queue_url)
DLQ=$(terraform output -raw dlq_url)
FIFO=$(terraform output -raw fifo_queue_url)

echo "--- 1. send + receive + delete (the normal happy path)"
aws sqs send-message --queue-url "$Q" --message-body '{"order_id": 42}' --query MessageId --output text
MSG=$(aws sqs receive-message --queue-url "$Q" --wait-time-seconds 1 --output json)
echo "$MSG" | python3 -c 'import json,sys; m=json.load(sys.stdin)["Messages"][0]; print("received:", m["Body"])'
RECEIPT=$(echo "$MSG" | python3 -c 'import json,sys; print(json.load(sys.stdin)["Messages"][0]["ReceiptHandle"])')
aws sqs delete-message --queue-url "$Q" --receipt-handle "$RECEIPT" # without this it comes back
echo "deleted"

echo "--- 2. a 'poison' message: received 3 times, never deleted -> DLQ"
aws sqs send-message --queue-url "$Q" --message-body '{"order_id": "broken"}' >/dev/null
for i in 1 2 3; do
  # --visibility-timeout 0 makes it visible again at once (simulates a crash)
  aws sqs receive-message --queue-url "$Q" --visibility-timeout 0 --wait-time-seconds 1 \
    --query 'Messages[0].Body' --output text | sed "s/^/attempt $i: /"
done
aws sqs receive-message --queue-url "$Q" --wait-time-seconds 1 --query 'Messages[0].Body' --output text | sed 's/^/4th receive on main queue: /'
aws sqs receive-message --queue-url "$DLQ" --wait-time-seconds 2 --query 'Messages[0].Body' --output text | sed 's/^/in DLQ: /'

echo "--- 3. FIFO: order kept within a message group"
for step in created paid shipped; do
  aws sqs send-message --queue-url "$FIFO" --message-group-id order-7 --message-body "order-7 $step" >/dev/null
done
aws sqs receive-message --queue-url "$FIFO" --max-number-of-messages 10 --query 'Messages[].Body' --output text | tr '\t' '\n'
