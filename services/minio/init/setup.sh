#!/bin/sh
set -e

# Wait for MinIO to be ready
mc alias set myminio http://minio-dev:9000 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

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

# Create scoped IAM user, policy, and service account
echo "Setting up IAM user and policy..."
APP_USER="nestlancer-app"

if ! mc admin user info myminio "${APP_USER}" >/dev/null 2>&1; then
  mc admin user add myminio "${APP_USER}" "${MINIO_SECRET_KEY}"
  echo "  ✅ IAM user '${APP_USER}' created"
else
  echo "  ⏭️  IAM user '${APP_USER}' already exists"
fi

cat > /tmp/app-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::nl-dev-*"]
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": ["arn:aws:s3:::nl-dev-*/*"]
    }
  ]
}
EOF

mc admin policy create myminio nestlancer-app-policy /tmp/app-policy.json 2>/dev/null || true
mc admin policy attach myminio nestlancer-app-policy --user "${APP_USER}"
echo "  ✅ IAM policy applied to '${APP_USER}'"

if ! mc admin user svcacct info myminio "${MINIO_ACCESS_KEY}" >/dev/null 2>&1; then
  mc admin user svcacct add \
    --access-key "${MINIO_ACCESS_KEY}" \
    --secret-key "${MINIO_SECRET_KEY}" \
    myminio "${APP_USER}"
  echo "  ✅ Service account '${MINIO_ACCESS_KEY}' created"
else
  echo "  ⏭️  Service account '${MINIO_ACCESS_KEY}' already exists"
fi

echo "✅ MinIO initialization complete"
