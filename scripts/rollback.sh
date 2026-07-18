#!/usr/bin/env bash
# Roll the backend deployment back to its previous revision.
# Usage: ./scripts/rollback.sh
set -euo pipefail

kubectl rollout undo deployment/backend-api
kubectl rollout status deployment/backend-api --timeout=180s
echo "Rollback complete. Current image:"
kubectl get deployment backend-api -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
