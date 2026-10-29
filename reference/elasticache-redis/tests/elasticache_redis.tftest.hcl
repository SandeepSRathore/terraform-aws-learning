mock_provider "aws" {
  mock_data "aws_subnets" {
    defaults = {
      ids = ["subnet-aaaa1111", "subnet-bbbb2222"]
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "172.31.0.0/16"
    }
  }
}

run "single_node_encrypted_redis" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.main.engine == "redis" && aws_elasticache_replication_group.main.num_cache_clusters == 1
    error_message = "Expected a single Redis node"
  }

  # Quirk: in AWS provider 6.x this attribute is a STRING ("true"), even though
  # the config says `true`. Comparing it with the bool true is always false.
  assert {
    condition     = aws_elasticache_replication_group.main.at_rest_encryption_enabled == "true"
    error_message = "Data at rest should be encrypted"
  }

  # Failover needs a replica to fail over to.
  assert {
    condition     = !aws_elasticache_replication_group.main.automatic_failover_enabled || aws_elasticache_replication_group.main.num_cache_clusters >= 2
    error_message = "Automatic failover requires 2+ nodes"
  }
}
