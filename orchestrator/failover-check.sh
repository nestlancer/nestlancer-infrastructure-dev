#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# FAILOVER CHECK — Dev stack resilience (DEV)
# Verifies stopping one container does not stop the others
# ═══════════════════════════════════════════════════════════════

SERVICES=("postgres" "redis-cache" "redis-pubsub" "rabbitmq" "mailpit" "minio")
CONTAINERS=(
    "postgres-dev"
    "redis-cache-dev"
    "redis-pubsub-dev"
    "rabbitmq-dev"
    "mailpit-dev"
    "minio-dev"
)
PASSED=0
FAILED=0
TOTAL=0

check_container_health() {
    local container="$1"
    local state
    state=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "not_found")
    [[ "$state" == "running" ]]
}

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   DEV STACK RESILIENCE CHECK                          ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# For each service, stop it and check others are still running
for i in "${!SERVICES[@]}"; do
    SERVICE="${SERVICES[$i]}"
    CONTAINER="${CONTAINERS[$i]}"
    TOTAL=$((TOTAL + 1))

    echo "── Step: stop $CONTAINER → others still running? ──"

    # Stop the service
    docker stop "$CONTAINER" >/dev/null 2>&1 || true
    sleep 2

    # Check remaining services
    ALL_OK=true
    for j in "${!CONTAINERS[@]}"; do
        if [[ "$j" != "$i" ]]; then
            if check_container_health "${CONTAINERS[$j]}"; then
                echo "  ✅ ${CONTAINERS[$j]} — still running"
            else
                echo "  ❌ ${CONTAINERS[$j]} — AFFECTED!"
                ALL_OK=false
            fi
        fi
    done

    if $ALL_OK; then
        echo "  ✅ OK — stopping $CONTAINER did not affect others"
        PASSED=$((PASSED + 1))
    else
        echo "  ❌ FAIL — stopping $CONTAINER affected other services"
        FAILED=$((FAILED + 1))
    fi

    # Restart the stopped service
    docker start "$CONTAINER" >/dev/null 2>&1 || true
    sleep 3
    echo ""
done

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   RESULT: ${PASSED}/${TOTAL} ok, ${FAILED} failed"
if [[ $FAILED -eq 0 ]]; then
    echo "║   ✅ ALL RESILIENCE CHECKS PASSED"
else
    echo "║   ❌ SOME CHECKS FAILED"
fi
echo "╚═══════════════════════════════════════════════════════╝"

[[ $FAILED -eq 0 ]]
