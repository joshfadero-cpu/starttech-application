#!/usr/bin/env bash
# Check application health through the public CloudFront endpoint.
# Usage: ./scripts/health-check.sh <cloudfront-domain>
set -euo pipefail

DOMAIN="${1:?Usage: health-check.sh <cloudfront-domain>}"

echo "Checking https://${DOMAIN}/api/health ..."
RESPONSE=$(curl -sf "https://${DOMAIN}/api/health")
echo "Response: ${RESPONSE}"
echo "${RESPONSE}" | grep -q '"database":"ok"' && echo "Database: OK"
echo "${RESPONSE}" | grep -q '"cache":"ok"' && echo "Cache: OK"
echo "Health check passed."
