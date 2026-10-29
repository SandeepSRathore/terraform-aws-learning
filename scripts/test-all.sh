#!/usr/bin/env bash
# Runs `terraform test` in every module and environment.
# Uses mock providers only: no AWS account or credentials needed.
#
# Usage: ./scripts/test-all.sh            (all)
#        ./scripts/test-all.sh ecs-fargate (one module)
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF="${TF:-terraform}"

if [ $# -gt 0 ]; then
  dirs=("$ROOT/modules/$1")
else
  dirs=("$ROOT"/modules/*/ "$ROOT"/environments/*/)
fi

failed=()
for dir in "${dirs[@]}"; do
  dir="${dir%/}"
  name="${dir#"$ROOT"/}"
  echo "=== $name ==="
  if ! (cd "$dir" && "$TF" init -input=false -backend=false >/dev/null && "$TF" fmt -check -recursive && "$TF" validate -no-color >/dev/null && "$TF" test -no-color); then
    failed+=("$name")
  fi
  echo
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "FAILED: ${failed[*]}"
  exit 1
fi
echo "All passed."
