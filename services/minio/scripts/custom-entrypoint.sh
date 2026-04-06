#!/bin/sh
set -e

# Start MinIO in the background
# We pass through all arguments to minio server
minio "$@" &
MINIO_PID=$!

# Execute the setup script
# Wait for MinIO to be ready
echo "Waiting for MinIO to start..."
timeout 30 sh -c 'until curl -s http://localhost:9000/minio/health/live; do sleep 1; done'

if [ -f "/setup.sh" ]; then
    echo "Running initialization script..."
    sh /setup.sh || echo "⚠️ Initialization script encountered an error, but continuing MinIO server..."
fi

# Wait for the MinIO process
echo "MinIO is ready and initialized."
wait $MINIO_PID
