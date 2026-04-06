#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# LOGS — Aggregate or per-service logs for DEV
# Usage: ./logs.sh [service|all|summary]
# ═══════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "═══════════════════════════════════════════════════"
echo "  Infrastructure Logs — DEV ENVIRONMENT"
echo "═══════════════════════════════════════════════════"

SERVICE="${1:-summary}"

case "$SERVICE" in
    summary)
        echo "═══ Showing last 20 lines for ALL containers ═══"
        SERVICES="postgres redis-cache redis-pubsub rabbitmq mailpit minio"
        for s in $SERVICES; do
            CONTAINER="${s}-dev"
            if docker inspect "$CONTAINER" >/dev/null 2>&1; then
                echo "── $CONTAINER ──"
                docker logs --tail=20 "$CONTAINER" 2>&1 || true
                echo ""
            fi
        done
        ;;
    all)
        echo "═══ Tailing ALL services (Ctrl+C to stop) ═══"
        SERVICES="postgres redis-cache redis-pubsub rabbitmq mailpit minio"
        for s in $SERVICES; do
            echo "── Tailing $s (dev) ──"
            make -C "$ROOT_DIR/services/$s" logs &
        done
        wait
        ;;
    *)
        # Handle specific service with or without -dev
        BASE_SERVICE="${SERVICE%-dev}"
        if [ -d "$ROOT_DIR/services/$BASE_SERVICE" ]; then
            make -C "$ROOT_DIR/services/$BASE_SERVICE" logs
        else
            echo "❌ Service '$SERVICE' not found"
            echo "   Available services: postgres, redis-cache, redis-pubsub, rabbitmq, mailpit, minio"
            echo "   Or use: 'all' to tail all, 'summary' (default) for quick view"
            exit 1
        fi
        ;;
esac
