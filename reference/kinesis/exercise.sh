#!/usr/bin/env bash
# Write 3 records, then read them back twice: reading doesn't consume them.
set -euo pipefail
cd "$(dirname "$0")"

S=$(terraform output -raw stream_name)

echo "--- put 3 records (same partition key = same shard, kept in order)"
for page in /home /pricing /signup; do
  # --cli-binary-format: send the data as plain text; the CLI base64-encodes it.
  aws kinesis put-record --stream-name "$S" --partition-key user-1 \
    --data "{\"user\":\"user-1\",\"page\":\"$page\"}" --cli-binary-format raw-in-base64-out \
    --query SequenceNumber --output text | sed "s|^|$page -> sequence |"
done

read_all() {
  SHARD=$(aws kinesis list-shards --stream-name "$S" --query 'Shards[0].ShardId' --output text)
  # TRIM_HORIZON = start from the oldest record still retained.
  IT=$(aws kinesis get-shard-iterator --stream-name "$S" --shard-id "$SHARD" \
    --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)
  # Data comes back base64-encoded.
  aws kinesis get-records --shard-iterator "$IT" --query 'Records[].Data' --output text |
    tr '\t' '\n' | while read -r d; do echo "$d" | base64 --decode; echo; done
}

echo "--- consumer A reads from the beginning"
read_all
echo "--- consumer B reads again: same 3 records (a stream is a log, not a queue)"
read_all
