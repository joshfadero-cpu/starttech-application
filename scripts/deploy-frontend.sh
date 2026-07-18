#!/usr/bin/env bash
# Build the React frontend and deploy it to S3 + CloudFront.
# Usage: ./scripts/deploy-frontend.sh <s3-bucket> <cloudfront-distribution-id>
set -euo pipefail

BUCKET="${1:?Usage: deploy-frontend.sh <s3-bucket> <distribution-id>}"
DISTRIBUTION_ID="${2:?Usage: deploy-frontend.sh <s3-bucket> <distribution-id>}"

cd "$(dirname "$0")/../frontend"

npm ci
VITE_API_BASE_URL=/api npm run build
aws s3 sync dist/ "s3://${BUCKET}" --delete
aws cloudfront create-invalidation --distribution-id "${DISTRIBUTION_ID}" --paths "/*"
echo "Frontend deployed to ${BUCKET} and cache invalidated."
