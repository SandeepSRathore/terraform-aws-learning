# Kinesis Data Streams = an ordered, replayable log of records (like Kafka).
# Unlike SQS, reading does NOT remove a record: many consumers can read the
# same stream independently, and you can replay from any point within the
# retention period. Use it for clickstreams, logs, IoT telemetry and analytics.
#
#   shard        -> a unit of capacity (1 MB/s in, 2 MB/s out) and of ordering
#   partition key -> picks the shard; records with the same key stay in order

resource "aws_kinesis_stream" "clicks" {
  name             = "clickstream"
  retention_period = 24 # hours (max 8760 = 1 year, costs extra after 24)

  # PROVISIONED: you choose shards. ON_DEMAND: AWS scales them (simpler, pricier at steady load).
  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
  shard_count = 1

  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis" # AWS-managed key, free
}
