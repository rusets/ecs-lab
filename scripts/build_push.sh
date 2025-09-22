#!/usr/bin/env bash
set -euo pipefail
REGION="${AWS_REGION:-$(aws configure get region || echo us-east-1)}"
REPO_URL="${1:-}"
if [[ -z "$REPO_URL" ]]; then
  echo "Usage: AWS_REGION=us-east-1 ./scripts/build_push.sh <ecr_repo_url>"
  exit 1
fi
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REPO_URL"
docker build -t myapp:latest ./app
docker tag myapp:latest "$REPO_URL:latest"
docker push "$REPO_URL:latest"
echo "Pushed $REPO_URL:latest"
