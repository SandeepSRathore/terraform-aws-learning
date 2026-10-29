#!/usr/bin/env bash
# Put 3 events on the bus; only the one matching the rule reaches the queue.
set -euo pipefail
cd "$(dirname "$0")"

BUS=$(terraform output -raw bus_name)
Q=$(terraform output -raw queue_url)

put() { # $1 = source, $2 = detail-type, $3 = detail JSON
  aws events put-events --entries "[{\"EventBusName\":\"$BUS\",\"Source\":\"$1\",\"DetailType\":\"$2\",\"Detail\":$(printf '%s' "$3" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')}]" \
    --query 'FailedEntryCount' --output text | sed "s|^|put $1/$2 $3 -> failed entries: |"
}

echo "--- put 3 events"
put app.orders OrderPlaced '{"order_id": 1, "amount": 30}'    # too small
put app.orders OrderPlaced '{"order_id": 2, "amount": 500}'   # matches
put app.billing OrderPlaced '{"order_id": 3, "amount": 900}'  # wrong source
sleep 2

echo "--- queue receives only order 2 (and only its detail, thanks to input_path)"
aws sqs receive-message --queue-url "$Q" --max-number-of-messages 10 --wait-time-seconds 3 \
  --query 'Messages[].Body' --output text | tr '\t' '\n'

echo "--- test a pattern without sending anything (handy when writing rules)"
aws events test-event-pattern \
  --event-pattern '{"source":["app.orders"],"detail":{"amount":[{"numeric":[">=",100]}]}}' \
  --event '{"id":"1","account":"123456789012","source":"app.orders","time":"2026-01-01T00:00:00Z","region":"us-east-1","resources":[],"detail-type":"OrderPlaced","detail":{"amount":150}}' \
  --query Result --output text | sed 's/^/amount 150 matches: /'
