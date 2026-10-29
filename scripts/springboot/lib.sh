# Shared settings and helpers for the scripts in this folder.
# Sourced by them (`source lib.sh`), not run on its own.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="$ROOT/apps/hello-springboot"
ENV_DIR="$ROOT/environments/dev"
JAR="$APP_DIR/target/hello-springboot.jar"
TF="${TF:-terraform}"

log() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# LocalStack mode is on when a script gets --localstack, or when the shell
# already has TF_VAR_use_localstack=true (from `source reference/localstack.env`).
enable_localstack() { export TF_VAR_use_localstack=true; }
use_localstack() { [ "${TF_VAR_use_localstack:-false}" = "true" ]; }

tf_output() { "$TF" -chdir="$ENV_DIR" output -raw "$1"; }

# Print "<HTTP status> <body>" for a GET request; fail if it can't connect.
# On LocalStack the instance is a Docker container whose IP the Mac can't
# route to, so the request is sent from inside the LocalStack container,
# which is on the same Docker network (and has Python, but no curl).
http_get() {
  if use_localstack; then
    docker exec -i localstack-aws python3 - "$1" <<'PY'
import sys, urllib.request, urllib.error
try:
    with urllib.request.urlopen(sys.argv[1], timeout=5) as r:
        print(r.status, r.read().decode())
except urllib.error.HTTPError as e:
    print(e.code, e.read().decode())
except Exception as e:
    sys.exit(f"cannot connect: {e}")
PY
  else
    local body
    body="$(curl -s -m 5 -w '\n%{http_code}' "$1")" || return 1
    printf '%s %s\n' "${body##*$'\n'}" "${body%$'\n'*}"
  fi
}
