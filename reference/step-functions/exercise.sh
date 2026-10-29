#!/usr/bin/env bash
# Run the workflow with a small, a big and an invalid order.
set -euo pipefail
cd "$(dirname "$0")"

SM=$(terraform output -raw state_machine_arn)
T=$(terraform output -raw table_name)

run() { # $1 = order id, $2 = amount
  EXE=$(aws stepfunctions start-execution --state-machine-arn "$SM" --name "order-$1" \
    --input "{\"order_id\":\"$1\",\"amount\":$2}" --query executionArn --output text)
  for _ in $(seq 1 20); do # STANDARD executions are asynchronous: poll for the result
    STATUS=$(aws stepfunctions describe-execution --execution-arn "$EXE" --query status --output text)
    [ "$STATUS" != RUNNING ] && break
    sleep 1
  done
  # The states this execution went through, in order.
  PATH_TAKEN=$(aws stepfunctions get-execution-history --execution-arn "$EXE" \
    --query 'events[?type==`PassStateEntered` || type==`ChoiceStateEntered` || type==`WaitStateEntered` || type==`TaskStateEntered` || type==`SucceedStateEntered` || type==`FailStateEntered`].stateEnteredEventDetails.name' \
    --output text | tr '\t' ' ')
  echo "order $1 (amount $2): $STATUS | path: $PATH_TAKEN"
}

echo "--- 3 executions"
run A1 40
run A2 250
run A3 -5

echo "--- orders saved in DynamoDB by the workflow itself"
aws dynamodb scan --table-name "$T" --query 'Items[].[order_id.S, amount.N]' --output text | sort
