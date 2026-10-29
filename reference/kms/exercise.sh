#!/usr/bin/env bash
# Direct encrypt/decrypt with KMS, then envelope encryption with a data key.
set -euo pipefail
cd "$(dirname "$0")"

ALIAS=$(terraform output -raw alias)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "--- 1. encrypt a small secret directly with KMS (max 4 KB)"
CIPHER=$(aws kms encrypt --key-id "$ALIAS" --plaintext 'card=4111-1111' \
  --cli-binary-format raw-in-base64-out --query CiphertextBlob --output text)
echo "ciphertext (base64, first 40 chars): ${CIPHER:0:40}..."

echo "--- decrypt: no key ID needed, the ciphertext records which key was used"
echo "$CIPHER" | base64 --decode >"$WORK/blob"
aws kms decrypt --ciphertext-blob "fileb://$WORK/blob" --query Plaintext --output text | base64 --decode
echo

echo "--- 2. envelope encryption for big data"
# KMS returns the data key twice: plaintext (use, then forget) and encrypted (store).
aws kms generate-data-key --key-id "$ALIAS" --key-spec AES_256 --output json >"$WORK/dk.json"
python3 -c 'import json,sys,base64; d=json.load(open(sys.argv[1])); open(sys.argv[2],"wb").write(base64.b64decode(d["CiphertextBlob"])); print(base64.b64decode(d["Plaintext"]).hex())' \
  "$WORK/dk.json" "$WORK/dk.enc" >"$WORK/dk.hex"
seq 1 2000 >"$WORK/big.txt" # ~9 KB, too big for kms encrypt
openssl enc -aes-256-cbc -K "$(cat "$WORK/dk.hex")" -iv 00000000000000000000000000000000 -in "$WORK/big.txt" -out "$WORK/big.enc"
rm "$WORK/dk.hex" # the plaintext key is thrown away; only dk.enc is kept with the data
echo "encrypted $(wc -c <"$WORK/big.txt" | tr -d ' ') bytes locally; stored key is encrypted"

echo "--- later: ask KMS to decrypt the data key, then decrypt the data locally"
KEY=$(aws kms decrypt --ciphertext-blob "fileb://$WORK/dk.enc" --query Plaintext --output text | base64 --decode | xxd -p -c 64)
openssl enc -d -aes-256-cbc -K "$KEY" -iv 00000000000000000000000000000000 -in "$WORK/big.enc" | tail -2

echo "--- key rotation status"
aws kms get-key-rotation-status --key-id "$(terraform output -raw key_id)" --query KeyRotationEnabled --output text
