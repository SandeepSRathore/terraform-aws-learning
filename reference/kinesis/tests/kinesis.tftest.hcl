mock_provider "aws" {}

run "one_encrypted_shard" {
  command = plan

  assert {
    condition     = aws_kinesis_stream.clicks.shard_count == 1 && aws_kinesis_stream.clicks.retention_period == 24
    error_message = "Expected 1 shard and 24h retention"
  }

  assert {
    condition     = aws_kinesis_stream.clicks.encryption_type == "KMS"
    error_message = "The stream should be encrypted"
  }
}
