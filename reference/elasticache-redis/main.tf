# ElastiCache = managed in-memory data stores: Redis/Valkey (and Memcached).
# Sub-millisecond reads for caching database results, sessions, rate limits,
# leaderboards and queues. Data lives in RAM, so treat it as a cache unless
# you enable persistence/replication.
#
# A "replication group" is the modern way to create Redis/Valkey: 1 primary
# plus optional replicas, with automatic failover when there are 2+ nodes.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "demo-cache"
  subnet_ids = data.aws_subnets.default.ids # prod: private subnets
}

resource "aws_security_group" "cache" {
  name        = "demo-cache"
  description = "Redis from inside the VPC only"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "redis" {
  security_group_id = aws_security_group.cache.id
  cidr_ipv4         = data.aws_vpc.default.cidr_block # prod: the app's security group
  from_port         = 6379
  to_port           = 6379
  ip_protocol       = "tcp"
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "demo-redis"
  description          = "Demo cache"

  engine         = "redis" # "valkey" is the open-source fork AWS now recommends (cheaper)
  engine_version = "7.1"
  node_type      = "cache.t4g.micro"
  port           = 6379

  num_cache_clusters         = 1     # prod: 2+ (primary + replica in another AZ)
  automatic_failover_enabled = false # requires 2+ nodes
  multi_az_enabled           = false

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.cache.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false # prod: true (clients then need TLS + usually an auth token)

  snapshot_retention_limit = 1 # daily snapshot kept 1 day
  apply_immediately        = true
}
