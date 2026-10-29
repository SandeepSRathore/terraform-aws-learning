#!/usr/bin/env bash
# List the zone's records and ask Route 53 what it would answer.
set -euo pipefail
cd "$(dirname "$0")"

Z=$(terraform output -raw zone_id)

echo "--- name servers to set at your registrar"
terraform output -json name_servers | python3 -c 'import json,sys; print("\n".join(json.load(sys.stdin)))'

echo "--- all records (NS and SOA are created automatically)"
aws route53 list-resource-record-sets --hosted-zone-id "$Z" \
  --query 'ResourceRecordSets[].[Name, Type, SetIdentifier || `-`, Weight || `-`, ResourceRecords[0].Value]' --output text

# test-dns-answer works on real AWS; LocalStack (2026.10) doesn't implement it.
echo "--- what would Route 53 answer? (no real DNS lookup needed)"
for q in "www.example-shop.com A" "blog.example-shop.com CNAME" "example-shop.com TXT"; do
  set -- $q
  aws route53 test-dns-answer --hosted-zone-id "$Z" --record-name "$1" --record-type "$2" \
    --query '[RecordName, RecordType, RecordData[0], ResponseCode]' --output text 2>/dev/null ||
    echo "$1 $2: test-dns-answer not supported here (real AWS only)"
done
# On real AWS, once the registrar points at the name servers above:
#   dig +short www.example-shop.com
