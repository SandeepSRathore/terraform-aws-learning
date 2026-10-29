#!/usr/bin/env bash
# Build, upload and run the Spring Boot app on EC2, then check it works:
#
#   build.sh  ->  terraform apply -var enable_springboot=true  ->  smoke-test.sh
#
# A new JAR (or changed settings) replaces the instance. An unchanged JAR
# changes nothing, because the build is reproducible (see pom.xml).
#
# Usage: scripts/springboot/deploy.sh [--localstack] [--yes] [--skip-tests] [-- <terraform args>]
#   --localstack   deploy to LocalStack instead of AWS
#   --yes          don't ask before applying (-auto-approve)
#   --skip-tests   build without running the app's tests
#   -- ...         passed to terraform apply, e.g. -- -var enable_ec2=false
source "$(dirname "$0")/lib.sh"

build_args=()
smoke_args=()
apply_args=(-var enable_springboot=true)
while [ $# -gt 0 ]; do
  case "$1" in
    --localstack) enable_localstack; smoke_args+=(--localstack) ;;
    --yes) apply_args+=(-auto-approve) ;;
    --skip-tests) build_args+=(--skip-tests) ;;
    --) shift; apply_args+=("$@"); break ;;
    *) die "unknown option: $1 (terraform arguments go after --)" ;;
  esac
  shift
done

if use_localstack; then
  curl -sf -m 3 http://localhost:4566/_localstack/health >/dev/null \
    || die "LocalStack isn't answering on localhost:4566. Start it: lstk start --non-interactive"
fi

"$(dirname "$0")/build.sh" ${build_args[@]+"${build_args[@]}"}

log "terraform apply in $ENV_DIR ($(use_localstack && echo LocalStack || echo AWS))"
"$TF" -chdir="$ENV_DIR" init -input=false >/dev/null
"$TF" -chdir="$ENV_DIR" apply "${apply_args[@]}"

"$(dirname "$0")/smoke-test.sh" ${smoke_args[@]+"${smoke_args[@]}"}
