#!/usr/bin/env bash
# Call the API with curl like any client would.
set -euo pipefail
cd "$(dirname "$0")"

URL=$(terraform output -raw api_url)
echo "API: $URL"

echo "--- GET /hello"
curl -s "$URL/hello"; echo
echo "--- GET /hello?name=Asha"
curl -s "$URL/hello?name=Asha"; echo
echo "--- POST /items"
curl -s -X POST -H 'content-type: application/json' -d '{"sku":"A-1","qty":2}' -w '  (HTTP %{http_code})' "$URL/items"; echo
echo "--- a route that doesn't exist"
curl -s -w '  (HTTP %{http_code})' "$URL/nope"; echo
