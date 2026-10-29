mock_provider "aws" {}

run "keys_index_ttl" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.shop.hash_key == "pk" && aws_dynamodb_table.shop.range_key == "sk"
    error_message = "Table should use pk/sk keys"
  }

  assert {
    condition     = one(aws_dynamodb_table.shop.global_secondary_index).name == "by-status"
    error_message = "The by-status index should exist"
  }

  assert {
    condition     = aws_dynamodb_table.shop.ttl[0].attribute_name == "expires_at"
    error_message = "TTL should use expires_at"
  }
}
