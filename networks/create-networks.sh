#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# CREATE NETWORKS — Creates gateway + internal networks for DEV
# ═══════════════════════════════════════════════════════════════════

# ── Subnet Definitions ──
GATEWAY_SUBNET="172.20.0.0/24"
PG_SUBNET="172.20.1.0/28"
RC_SUBNET="172.20.2.0/28"
RP_SUBNET="172.20.3.0/28"
RMQ_SUBNET="172.20.4.0/28"
MAILPIT_SUBNET="172.20.7.0/28"
MINIO_SUBNET="172.20.8.0/28"

create_network() {
    local name="$1"
    local subnet="$2"
    local internal="${3:-false}"

    if docker network inspect "$name" >/dev/null 2>&1; then
        echo "  ⏭️  Network '$name' already exists — skipping"
        return 0
    fi

    local cmd="docker network create --driver bridge --subnet=$subnet"
    if [[ "$internal" == "true" ]]; then
        cmd="$cmd --internal"
    fi
    cmd="$cmd $name"

    eval "$cmd"
    echo "  ✅ Created network '$name' (subnet: $subnet)"
}

echo "═══════════════════════════════════════════════════"
echo "  Creating networks for DEV ENVIRONMENT"
echo "═══════════════════════════════════════════════════"

# Gateway network (cross-service communication)
create_network "gateway_dev_network" "$GATEWAY_SUBNET" "false"

# Internal networks (service-specific, isolated)
create_network "pg_internal_dev" "$PG_SUBNET" "true"
create_network "rc_internal_dev" "$RC_SUBNET" "true"
create_network "rp_internal_dev" "$RP_SUBNET" "true"
create_network "rmq_internal_dev" "$RMQ_SUBNET" "true"
create_network "mailpit_internal_dev" "$MAILPIT_SUBNET" "true"
create_network "minio_internal_dev" "$MINIO_SUBNET" "true"

echo ""
echo "✅ All networks for DEV created successfully"
