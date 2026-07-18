#!/usr/bin/env bash
# Build, push and deploy the backend image to EKS.
# Usage: ./scripts/deploy-backend.sh <ecr-repository-url> [tag]
set -euo pipefail

ECR_URL="${1:?Usage: deploy-backend.sh <ecr-repository-url> [tag]}"
TAG="${2:-manual-$(date +%Y%m%d%H%M%S)}"
REGION="eu-west-1"

cd "$(dirname "$0")/.."

aws ecr get-login-password --region "${REGION}" | \
  docker login --username AWS --password-stdin "${ECR_URL%%/*}"

docker build --platform linux/amd64 -t "${ECR_URL}:${TAG}" backend/
docker push "${ECR_URL}:${TAG}"

sed "s|image: IMAGE_PLACEHOLDER|image: ${ECR_URL}:${TAG}|" k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml -f k8s/ingress.yaml
kubectl rollout status deployment/backend-api --timeout=180s
echo "Backend ${TAG} deployed."
