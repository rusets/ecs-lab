#!/usr/bin/env bash
set -euo pipefail
NS="app"
REGION="${AWS_REGION:-$(aws configure get region || echo us-east-1)}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo 000000000000)"
REPO="${ECR_REPOSITORY:-myapp}"
IMAGE="${1:-${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO}:latest}"

echo "Using image: $IMAGE"
sed -i.bak "s#image: .*amazonaws.com/.\+#image: ${IMAGE}#g" k8s/app/deployment.yaml

kubectl apply -f k8s/app/namespace.yaml
kubectl apply -f k8s/app/deployment.yaml
kubectl apply -f k8s/app/service.yaml
kubectl apply -f k8s/app/hpa.yaml

kubectl get svc -n "$NS" -o wide
