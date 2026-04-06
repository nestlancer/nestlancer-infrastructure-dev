#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# DESTROY NETWORKS — Removes all networks for DEV
# ═══════════════════════════════════════════════════════════════════

remove_network() {
    local name="$1"
    if docker network inspect "$name" >/dev/null 2>&1; then
        docker network rm "$name" >/dev/null 2>&1 || true
        echo "  🗑️  Removed network '$name'"
    else
        echo "  ⏭️  Network '$name' does not exist — skipping"
    fi
}

echo "═══════════════════════════════════════════════════"
echo "  Destroying networks for DEV ENVIRONMENT"
echo "═══════════════════════════════════════════════════"

remove_network "gateway_dev_network"
remove_network "pg_internal_dev"
remove_network "rc_internal_dev"
remove_network "rp_internal_dev"
remove_network "rmq_internal_dev"
remove_network "mailpit_internal_dev"
remove_network "minio_internal_dev"

echo ""
echo "✅ All networks for DEV destroyed"
