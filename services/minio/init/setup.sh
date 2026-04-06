#!/bin/sh
set -e

# Wait for MinIO to be ready
mc alias set myminio http://minio:9000 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

echo "Creating buckets..."
BUCKETS="
  nl-dev-media-private
  nl-dev-media-public
  nl-dev-user-avatars
  nl-dev-service-requests
  nl-dev-sales-quotes
  nl-dev-project-outputs
  nl-dev-admin-reports
  nl-dev-billing-receipts
"

for bucket in $BUCKETS; do
  if ! mc ls "myminio/$bucket" >/dev/null 2>&1; then
    mc mb "myminio/$bucket"
    echo "  ✅ Bucket '$bucket' created"
  else
    echo "  ⏭️  Bucket '$bucket' already exists"
  fi
done

# Create API Key (Service Account)
echo "Setting up API Key..."
if ! mc admin user svcacct info myminio "${MINIO_ACCESS_KEY}" >/dev/null 2>&1; then
  mc admin user svcacct add \
    --access-key "${MINIO_ACCESS_KEY}" \
    --secret-key "${MINIO_SECRET_KEY}" \
    myminio "${MINIO_ROOT_USER}"
  echo "  ✅ Service account '${MINIO_ACCESS_KEY}' created"
else
  echo "  ⏭️  Service account '${MINIO_ACCESS_KEY}' already exists"
fi

echo "✅ MinIO initialization complete"
