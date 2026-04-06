#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# STATUS — Dev Environment status dashboard
# ═══════════════════════════════════════════════════════════════
DEV_CONTAINERS=(
    "postgres-dev"
    "postgres-replica-dev"
    "redis-cache-dev"
    "redis-pubsub-dev"
    "rabbitmq-dev"
    "mailpit-dev"
    "minio-dev"
)

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                  INFRASTRUCTURE STATUS DASHBOARD (DEV)                   ║"
echo "╠══════════════════════╦══════════╦══════════╦════════════╦════════════════╣"
printf "║ %-20s ║ %-8s ║ %-8s ║ %-10s ║ %-14s ║\n" "CONTAINER" "STATE" "HEALTH" "PORTS" "UPTIME"
echo "╠══════════════════════╬══════════╬══════════╬════════════╬════════════════╣"

for container in "${DEV_CONTAINERS[@]}"; do
    if docker inspect "$container" >/dev/null 2>&1; then
        STATE=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
        HEALTH=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}' "$container" 2>/dev/null)
        PORTS=$(docker port "$container" 2>/dev/null | head -1 | sed 's/.*://;s/ //g' || echo "—")
        STARTED=$(docker inspect --format='{{.State.StartedAt}}' "$container" 2>/dev/null)

        # Calculate uptime
        if [[ "$STATE" == "running" ]]; then
            # MacOS/Linux cross-compatibility for date -d is tricky, using raw bash if possible or just the string
            UPTIME=$(docker inspect --format='{{.State.StartedAt}}' "$container" | cut -d. -f1 | sed 's/T/ /')
            # For simplicity, we just show the start time if date calculation is complex on the system
            # But let's try a simple version
            START_EPOCH=$(date -d "$STARTED" +%s 2>/dev/null || echo "0")
            if [[ "$START_EPOCH" != "0" ]]; then
                NOW_EPOCH=$(date +%s)
                DIFF=$((NOW_EPOCH - START_EPOCH))
                if [[ $DIFF -lt 60 ]]; then UPTIME="${DIFF}s"
                elif [[ $DIFF -lt 3600 ]]; then UPTIME="$((DIFF / 60))m"
                else UPTIME="$((DIFF / 3600))h $((DIFF % 3600 / 60))m"
                fi
            fi
        else
            UPTIME="—"
        fi

        # State Icon
        case "$STATE" in
            running) STATE_ICON="✅ run" ;;
            exited)  STATE_ICON="❌ exit" ;;
            *)       STATE_ICON="⚠️  $STATE" ;;
        esac

        # Health Icon
        case "$HEALTH" in
            healthy)   HEALTH_ICON="✅ ok" ;;
            unhealthy) HEALTH_ICON="❌ bad" ;;
            starting)  HEALTH_ICON="⏳ init" ;;
            *)         HEALTH_ICON="— N/A" ;;
        esac

        printf "║ %-20s ║ %-8s ║ %-8s ║ %-10s ║ %-14s ║\n" \
            "$container" "$STATE_ICON" "$HEALTH_ICON" "$PORTS" "$UPTIME"
    else
        printf "║ %-20s ║ %-8s ║ %-8s ║ %-10s ║ %-14s ║\n" \
            "$container" "❌ none" "—" "—" "—"
    fi
done

echo "╚══════════════════════╩══════════╩══════════╩════════════╩════════════════╝"
