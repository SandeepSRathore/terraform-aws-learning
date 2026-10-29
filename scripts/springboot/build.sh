#!/usr/bin/env bash
# Step 1 of a deploy: build the Spring Boot fat JAR (and run the app's tests).
#
# Usage: scripts/springboot/build.sh [--skip-tests]
source "$(dirname "$0")/lib.sh"

mvn_args=(-B -q package)
for arg in "$@"; do
  case "$arg" in
    --skip-tests) mvn_args+=(-DskipTests) ;;
    *) die "unknown option: $arg" ;;
  esac
done

# Prefer an installed Maven; the project's wrapper downloads one if needed.
MVN="$(command -v mvn || echo ./mvnw)"

log "Build $APP_DIR"
(cd "$APP_DIR" && "$MVN" "${mvn_args[@]}")

[ -f "$JAR" ] || die "the build finished but $JAR is missing"
echo "JAR:     $JAR ($(du -h "$JAR" | cut -f1))"
# The same SHA-256 that Terraform bakes into user_data and the instance verifies.
echo "SHA-256: $(shasum -a 256 "$JAR" | cut -d' ' -f1)"
