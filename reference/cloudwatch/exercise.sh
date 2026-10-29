#!/usr/bin/env bash
# Write logs, search them, publish a metric, and push the alarm through to SNS.
set -euo pipefail
cd "$(dirname "$0")"

LG=$(terraform output -raw log_group)
ALARM=$(terraform output -raw alarm_name)
INBOX=$(terraform output -raw alerts_inbox_url)
NOW_MS=$(($(date +%s) * 1000))

echo "--- write 4 log lines (what an app's logging library does for you)"
aws logs create-log-stream --log-group-name "$LG" --log-stream-name web-1
aws logs put-log-events --log-group-name "$LG" --log-stream-name web-1 --log-events \
  "timestamp=$NOW_MS,message=INFO started" \
  "timestamp=$((NOW_MS + 1)),message=ERROR db timeout" \
  "timestamp=$((NOW_MS + 2)),message=INFO request ok" \
  "timestamp=$((NOW_MS + 3)),message=ERROR db timeout again" --query nextSequenceToken --output text >/dev/null

echo "--- search the logs for ERROR"
aws logs filter-log-events --log-group-name "$LG" --filter-pattern ERROR --query 'events[].message' --output text | tr '\t' '\n'

echo "--- publish a custom metric directly (apps can do this too) and read it back"
aws cloudwatch put-metric-data --namespace Demo/App --metric-name ErrorCount --value 7 --unit Count
aws cloudwatch get-metric-statistics --namespace Demo/App --metric-name ErrorCount --statistics Sum \
  --start-time "$(date -u -v-5M +%Y-%m-%dT%H:%M:%SZ)" --end-time "$(date -u -v+1M +%Y-%m-%dT%H:%M:%SZ)" \
  --period 300 --query 'Datapoints[].Sum' --output text | sed 's/^/sum of ErrorCount in the last 5 min: /'

# Real alarms evaluate every period (here 60s). To test the notification
# path right away, force the state; the alarm then fires its actions.
echo "--- force the alarm into ALARM and check the alert arrived via SNS"
aws cloudwatch set-alarm-state --alarm-name "$ALARM" --state-value ALARM --state-reason "testing the alert path"
aws cloudwatch describe-alarms --alarm-names "$ALARM" --query 'MetricAlarms[0].StateValue' --output text | sed 's/^/alarm state: /'
aws sqs receive-message --queue-url "$INBOX" --wait-time-seconds 5 --query 'Messages[0].Body' --output text |
  python3 -c 'import json,sys; m=json.load(sys.stdin); print("alert received:", m["AlarmName"], "->", m["NewStateValue"], "|", m["NewStateReason"])'
