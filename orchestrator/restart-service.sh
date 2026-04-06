#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# RESTART SERVICE — Restart a single dev service
# Usage: ./restart-service.sh <service>
# ═══════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

SERVICE="${1:-}"

if [[ -z "$SERVICE" ]]; then
    echo "❌ Usage: $0 <postgres|redis-cache|redis-pubsub|rabbitmq|mailpit|minio>"
    exit 1
fi

# Handle service name with or without -dev
BASE_SERVICE="${SERVICE%-dev}"

if [[ ! -d "$ROOT_DIR/services/$BASE_SERVICE" ]]; then
    echo "❌ Invalid service: $SERVICE"
    echo "   Available: postgres, redis-cache, redis-pubsub, rabbitmq, mailpit, minio"
    exit 1
fi

echo "🔄 Restarting $BASE_SERVICE (dev)..."
make -C "$ROOT_DIR/services/$BASE_SERVICE" restart
echo "✅ $BASE_SERVICE (dev) restarted"
