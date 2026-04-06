#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# START ALL — Start all services for DEV environment
# ═══════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

export APP_ENV="dev"

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   Starting ALL services for DEV ENVIRONMENT            ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Create networks first
"$ROOT_DIR/networks/create-networks.sh"
echo ""

# Start each service
SERVICES="postgres redis-cache redis-pubsub rabbitmq mailpit minio"

for service in $SERVICES; do
    echo "── Starting $service (dev) ──"
    make -C "$ROOT_DIR/services/$service" up
    echo ""
done

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   ✅ All services for DEV started                     ║"
echo "╚═══════════════════════════════════════════════════════╝"
