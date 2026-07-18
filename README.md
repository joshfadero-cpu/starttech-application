# starttech-application

MuchToDo full-stack application (React + Golang) with Kubernetes manifests, deployment scripts, and GitHub Actions CI/CD, deployed on the infrastructure provisioned by [starttech-infra](https://github.com/joshfadero-cpu/starttech-infra).

Application source imported from [Innocent9712/much-to-do](https://github.com/Innocent9712/much-to-do) (`feature/full-stack`), restructured as `frontend/` and `backend/`.

## Layout

- `frontend/` React (Vite + TypeScript). Calls the API with relative paths via `VITE_API_BASE_URL=/api`, so all traffic stays on the CloudFront domain and mixed content never occurs
- `backend/` Golang (Gin) REST API with MongoDB (Atlas) persistence and Redis (ElastiCache) session caching. Structured JSON logs to stdout. Multi-stage Dockerfile: static binary, non-root user, wget-based GET healthcheck on `/health`
- `k8s/` Deployment (2 replicas, RollingUpdate maxSurge 1 / maxUnavailable 0, readiness and liveness probes), NodePort Service pinned to 30080 (the contract with the Terraform-managed ALB target group), and an Ingress documenting routing intent (inert without the AWS LB Controller; external ALB is Terraform-managed)
- `scripts/` deploy-frontend, deploy-backend, health-check, rollback
- `.github/workflows/` frontend and backend pipelines

## Configuration

The backend reads configuration from environment variables and an optional `.env` file (Viper). In-cluster, two Kubernetes secrets supply both forms:

- `backend-env`: all keys injected as environment variables (`envFrom`)
- `backend-env-file`: the same content mounted as `.env` at the app working directory, covering keys Viper does not bind from the environment without registered defaults

Key variables: `MONGO_URI` (Atlas SRV string), `DB_NAME`, `JWT_SECRET_KEY`, `ENABLE_CACHE=true`, `REDIS_ADDR` (host:port) and `REDIS_HOST` (host), `LOG_FORMAT=json`, `SECURE_COOKIE=true`, `COOKIE_DOMAINS`/`ALLOWED_ORIGINS` set to the CloudFront domain. Secrets are never committed; see the infra repository's bring-up checklist.

## CI/CD

- `frontend-ci-cd.yml` (on `frontend/**`): `npm ci`, `npm audit` (fails on critical; the inherited dependency tree carries known non-critical advisories), `npm run build` with `VITE_API_BASE_URL=/api`, `aws s3 sync`, CloudFront invalidation
- `backend-ci-cd.yml` (on `backend/**` or `k8s/**`): `go test ./...`, Docker build tagged with the git SHA, Trivy scan (fails on critical), ECR push, manifest image patch (template `IMAGE_PLACEHOLDER` is substituted on the runner, never committed), `aws eks update-kubeconfig`, `kubectl apply -f k8s/`, `kubectl rollout status deployment/backend-api`

ECR additionally scans images on push. Pipeline AWS credentials are repository secrets for a dedicated CI IAM user with an EKS access entry granting cluster admin.

## Manual deployment

```bash
./scripts/deploy-backend.sh <ecr-repository-url> [tag]
./scripts/deploy-frontend.sh <s3-bucket> <cloudfront-distribution-id>
./scripts/health-check.sh <cloudfront-domain>
./scripts/rollback.sh
```

Values for the arguments come from `terraform output` in the infrastructure repository. Local backend builds use `--platform linux/amd64` (Apple Silicon developers, amd64 worker nodes); CI builds natively on amd64 runners.

## Verification

`https://<cloudfront-domain>/api/health` returns `{"cache":"ok","database":"ok"}` when the full chain (CloudFront function, ALB, NodePort, pod, Atlas, ElastiCache) is healthy. The in-app Health page polls the same endpoint.
