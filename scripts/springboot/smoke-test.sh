#!/usr/bin/env bash
# Step 3 of a deploy: wait until the app on EC2 passes its health check,
# then call it once. `terraform apply` returns as soon as the instance is
# "running"; Java still has to be installed and the app started after that.
#
# Usage: scripts/springboot/smoke-test.sh [--localstack] [--timeout SECONDS]
source "$(dirname "$0")/lib.sh"

timeout=300
while [ $# -gt 0 ]; do
  case "$1" in
    --localstack) enable_localstack ;;
    --timeout) timeout="$2"; shift ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

app_url="$(tf_output springboot_url)" || die "no springboot_url output: is enable_springboot = true and applied?"
health_url="$(tf_output springboot_health_url)"

log "Wait up to ${timeout}s for $health_url"
start=$SECONDS
until response="$(http_get "$health_url" 2>/dev/null)" && [ "${response%% *}" = "200" ]; do
  if (( SECONDS - start >= timeout )); then
    echo "Last response: ${response:-no connection}"
    die "not healthy after ${timeout}s. See what the instance did: scripts/springboot/logs.sh"
  fi
  printf '.'
  sleep 5
done
echo
echo "healthy after $(( SECONDS - start ))s: ${response#* }"

log "GET $app_url/"
response="$(http_get "$app_url/")"
[ "${response%% *}" = "200" ] || die "GET / returned: $response"
echo "${response#* }"
