# DynamoDB = a serverless key-value / document database. No server to size:
# you get single-digit-millisecond reads at any scale, but you must design the
# table around your ACCESS PATTERNS, because you can only query efficiently by key.
#
# Keys:
#   partition key (pk) -> which partition stores the item; must be in every query
#   sort key (sk)      -> orders items inside a partition; allows begins_with/between
# Here, one customer's profile and orders share a partition (pk = CUSTOMER#id),
# so one query returns all of them ("single-table design").
#
# Also shown: a global secondary index (GSI) for a second access pattern,
# TTL (auto-delete expired items), and point-in-time recovery (backups).

resource "aws_dynamodb_table" "shop" {
  name         = "shop"
  billing_mode = "PAY_PER_REQUEST" # on-demand: pay per request, no capacity planning

  hash_key  = "pk"
  range_key = "sk"

  # Declare ONLY attributes used as keys (table or index). Other attributes
  # need no schema: every item can have different fields.
  attribute {
    name = "pk"
    type = "S" # S = string, N = number, B = binary
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  # Second access pattern: "all orders with status X, newest first".
  # (AWS provider 6.x: index keys use key_schema blocks; hash_key/range_key
  # inside an index are deprecated. HASH = partition key, RANGE = sort key.)
  global_secondary_index {
    name            = "by-status"
    projection_type = "ALL" # copy every attribute into the index

    key_schema {
      attribute_name = "status"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "sk"
      key_type       = "RANGE"
    }
  }

  # Items whose expires_at (Unix seconds) is in the past get deleted for free.
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true # restore to any second in the last 35 days
  }

  server_side_encryption {
    enabled = true
  }
}
