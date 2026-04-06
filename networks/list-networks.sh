#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# LIST NETWORKS — Dev environment Docker networks only
# Usage: ./list-networks.sh
# ═══════════════════════════════════════════════════════════════════

NETWORKS=(
    "gateway_dev_network"
    "pg_internal_dev"
    "rc_internal_dev"
    "rp_internal_dev"
    "rmq_internal_dev"
    "mailpit_internal_dev"
    "minio_internal_dev"
)

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                 DEV NETWORK STATUS                               ║"
echo "╠════════════════════════════╦══════════╦══════════════════════════╣"
printf "║ %-26s ║ %-8s ║ %-24s ║\n" "NETWORK NAME" "STATUS" "SUBNET"
echo "╠════════════════════════════╬══════════╬══════════════════════════╣"

for net in "${NETWORKS[@]}"; do
    if docker network inspect "$net" >/dev/null 2>&1; then
        subnet=$(docker network inspect "$net" --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null || echo "N/A")
        printf "║ %-26s ║ %-8s ║ %-24s ║\n" "$net" "✅ UP" "$subnet"
    else
        printf "║ %-26s ║ %-8s ║ %-24s ║\n" "$net" "❌ DOWN" "—"
    fi
done

echo "╚════════════════════════════╩══════════╩══════════════════════════╝"
