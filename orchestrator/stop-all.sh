#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# STOP ALL — Stop all services for DEV environment
# ═══════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   Stopping ALL services for DEV ENVIRONMENT            ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Stop each service
SERVICES="postgres redis-cache redis-pubsub rabbitmq mailpit minio"

for service in $SERVICES; do
    echo "── Stopping $service (dev) ──"
    make -C "$ROOT_DIR/services/$service" down
    echo ""
done

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   ✅ All services for DEV stopped                     ║"
echo "╚═══════════════════════════════════════════════════════╝"
