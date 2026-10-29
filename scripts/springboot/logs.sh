#!/usr/bin/env bash
# Show what the instance's bootstrap script did. Use it when smoke-test.sh fails.
#
# Usage: scripts/springboot/logs.sh [--localstack]
source "$(dirname "$0")/lib.sh"

for arg in "$@"; do
  case "$arg" in
    --localstack) enable_localstack ;;
    *) die "unknown option: $arg" ;;
  esac
done

instance_id="$(tf_output springboot_instance_id)" || die "no springboot_instance_id output"

if use_localstack; then
  # LocalStack runs the instance as a Docker container named after its ID.
  container="localstack-ec2.$instance_id"
  log "Bootstrap log ($container:/var/log/hello-springboot-bootstrap.log)"
  docker exec "$container" cat /var/log/hello-springboot-bootstrap.log
  log "App log (last 30 lines)"
  docker exec "$container" tail -n 30 /var/log/hello-springboot.log
else
  # The serial console shows cloud-init's output, user_data included.
  # Once the app runs under systemd, its own logs are in the journal:
  #   aws ssm start-session --target <id>, then: journalctl -u hello-springboot
  log "Console output of $instance_id (can lag a few minutes behind)"
  aws ec2 get-console-output --instance-id "$instance_id" --latest --output text
fi
