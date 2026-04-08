# MinIO Service (Dev)

## Service Overview
This service runs a single-node MinIO instance for development object storage.
It uses a dedicated `minio-init` sidecar to create buckets and IAM resources after MinIO becomes healthy.

## Bucket Layout
The init process ensures these buckets exist:
- `nl-dev-media-private`
- `nl-dev-media-public`
- `nl-dev-user-avatars`
- `nl-dev-service-requests`
- `nl-dev-sales-quotes`
- `nl-dev-project-outputs`
- `nl-dev-admin-reports`
- `nl-dev-billing-receipts`

## IAM and Service Account
- Root credentials come from `env/dev.env` and are used only for bootstrap.
- Init creates IAM user `nestlancer-app`.
- Init creates and attaches `nestlancer-app-policy` scoped to `nl-dev-*` buckets.
- Init creates service account keys from:
  - `MINIO_ACCESS_KEY`
  - `MINIO_SECRET_KEY`

## Ports
- `9000` -> MinIO API
- `9001` -> MinIO Console

## Volume Location
- Host path: `${DATA_PATH_BASE}/minio_data`
- Default base in Makefile: `/root/Desktop/docker-infra-data/dev/minio`

## Init Process
`minio-init` runs once and exits (`restart: "no"`):
1. Waits for MinIO health check success.
2. Sets `mc` alias against `minio-dev:9000`.
3. Creates required buckets (idempotent).
4. Creates/updates IAM user, policy, and service account (idempotent).

## Health Check
MinIO health endpoint:
- `http://localhost:9000/minio/health/live`
- Interval: `30s`
- Timeout: `10s`
- Retries: `5`
- Start period: `30s`

## Makefile Commands
Run from `services/minio`:
- `make up` - create networks and start stack
- `make down` - stop stack
- `make restart` - restart services
- `make logs` - tail compose logs
- `make status` - show MinIO container status
- `make shell` - open shell in `minio-init` container
- `make clean` - stop and remove stack volumes
