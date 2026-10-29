#!/usr/bin/env bash
# Publish two orders once each; see fan-out and the filter policy at work.
set -euo pipefail
cd "$(dirname "$0")"

TOPIC=$(terraform output -raw topic_arn)
ALL=$(terraform output -raw all_orders_queue_url)
BIG=$(terraform output -raw big_orders_queue_url)

publish() { # $1 = body, $2 = amount (a message ATTRIBUTE, which filters look at)
  aws sns publish --topic-arn "$TOPIC" --message "$1" \
    --message-attributes "{\"amount\":{\"DataType\":\"Number\",\"StringValue\":\"$2\"}}" \
    --query MessageId --output text | sed "s/^/published '$1' -> /"
}

echo "--- publish 2 messages to the topic"
publish "small order (25)" 25
publish "big order (250)" 250
sleep 1

bodies() { aws sqs receive-message --queue-url "$1" --max-number-of-messages 10 --wait-time-seconds 2 --query 'Messages[].Body' --output text | tr '\t' '\n'; }

echo "--- all-orders queue (no filter): gets both"
bodies "$ALL"
echo "--- big-orders queue (filter amount >= 100): gets only the big one"
bodies "$BIG"
