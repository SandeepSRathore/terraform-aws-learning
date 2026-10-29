#!/usr/bin/env bash
# Log Docker in to ECR, push a tiny image, list it, and see tag immutability.
set -euo pipefail
cd "$(dirname "$0")"

REPO_URL=$(terraform output -raw repository_url)
REPO=$(terraform output -raw repository_name)
REGISTRY=${REPO_URL%%/*}
SRC=alpine:3.20 # any small local image

echo "--- docker login (ECR gives a 12-hour password via IAM)"
aws ecr get-login-password | docker login --username AWS --password-stdin "$REGISTRY" 2>&1 | tail -1

echo "--- tag and push $SRC as v1.0.0"
docker image inspect "$SRC" >/dev/null 2>&1 || docker pull -q "$SRC"
docker tag "$SRC" "$REPO_URL:v1.0.0"
docker push -q "$REPO_URL:v1.0.0"

echo "--- images in the repository"
aws ecr describe-images --repository-name "$REPO" \
  --query 'imageDetails[].[imageTags[0], imageSizeInBytes, imageDigest]' --output text

# Real AWS rejects this push: "tag invalid: The image tag 'v1.0.0' already
# exists ... and cannot be overwritten because the repository is immutable."
# LocalStack (2026.10) does NOT enforce immutability and accepts it.
echo "--- push v1.0.0 again with different content (real AWS refuses: IMMUTABLE)"
# A one-line rebuild with an extra label is enough to change the image digest.
printf 'FROM %s\nLABEL changed=true\n' "$SRC" | docker build -q -t "$REPO_URL:v1.0.0" - >/dev/null
if OUT=$(docker push "$REPO_URL:v1.0.0" 2>&1); then
  echo "push ACCEPTED (this registry did not enforce immutability)"
else
  echo "push REJECTED: $(echo "$OUT" | tail -1)"
fi
aws ecr describe-images --repository-name "$REPO" --query 'imageDetails[].[imageTags[0], imageDigest]' --output text

echo "--- clean up local tags"
docker rmi -f "$REPO_URL:v1.0.0" >/dev/null
