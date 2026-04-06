#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# DESTROY ALL — Remove all dev services + networks
# ═══════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   Destroying ALL DEV infrastructure                    ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Stop services and remove volumes
SERVICES="postgres redis-cache redis-pubsub rabbitmq mailpit minio"
for service in $SERVICES; do
    echo "── Cleaning $service (dev) ──"
    make -C "$ROOT_DIR/services/$service" clean
    echo ""
done

# Destroy networks
"$ROOT_DIR/networks/destroy-networks.sh"

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   ✅ All DEV infrastructure destroyed                 ║"
echo "╚═══════════════════════════════════════════════════════╝"
