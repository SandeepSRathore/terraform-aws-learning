#!/usr/bin/env bash
# Use Redis as a cache: set with expiry, counters, and a leaderboard.
set -euo pipefail
cd "$(dirname "$0")"

HOST=$(terraform output -raw primary_endpoint)
# Ask the API for the endpoint's real port: LocalStack remaps 6379 to its own
# port range, and on real AWS this returns the configured port anyway.
PORT=$(aws elasticache describe-replication-groups --replication-group-id demo-redis \
  --query 'ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint.Port' --output text)

echo "--- replication group"
aws elasticache describe-replication-groups --replication-group-id demo-redis \
  --query 'ReplicationGroups[0].[Status, CacheNodeType, NodeGroups[0].PrimaryEndpoint.Address, NodeGroups[0].PrimaryEndpoint.Port]' --output text

# redis-cli from the redis image. LocalStack's Redis listens on your Mac
# (host.docker.internal from a container); on real AWS run it inside the VPC.
CONNECT_HOST=$HOST
[ -n "${AWS_ENDPOINT_URL:-}" ] && CONNECT_HOST=host.docker.internal
r() { docker run --rm redis:8-alpine redis-cli -h "$CONNECT_HOST" -p "$PORT" "$@"; }

echo "--- cache a value for 60 seconds (the cache-aside pattern's 'set')"
r SET user:42:profile '{"name":"Asha"}' EX 60
r GET user:42:profile
r TTL user:42:profile | sed 's/^/seconds left: /'

echo "--- atomic counter (rate limiting, page views)"
r INCR page:home:views >/dev/null
r INCR page:home:views >/dev/null
r INCR page:home:views | sed 's/^/views: /'

echo "--- leaderboard with a sorted set"
r ZADD leaderboard 120 asha 95 ravi 150 meera >/dev/null
r ZREVRANGE leaderboard 0 2 WITHSCORES | paste - - | sed 's/^/  /'
