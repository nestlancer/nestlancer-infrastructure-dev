# ═══════════════════════════════════════════════════════════════
# PostgreSQL Service — Dev Environment Makefile
# ═══════════════════════════════════════════════════════════════

.PHONY: help up down restart logs shell status \
        build rebuild clean backup restore \
        network-create network-destroy

export APP_ENV := dev

# ── Derived variables ──
COMPOSE_FILE     := compose/docker-compose.yml
ENV_FILE         := env/dev.env
PROJECT_NAME     := pg-dev
CONTAINER_NAME   := postgres-dev
REPLICA_CONTAINER  := postgres-replica-dev
GATEWAY_NETWORK := gateway_dev_network
INTERNAL_NETWORK := pg_internal_dev

# ── Paths ──
export DATA_PATH_BASE := /root/Desktop/docker-infra-data/dev/postgres

# ── Network Config ──
GATEWAY_SUBNET  := 172.20.0.0/24
INTERNAL_SUBNET := 172.20.1.0/28

# Common docker compose command
DC := docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(PROJECT_NAME)

# ══════════════════════════════════════════════
# Help
# ══════════════════════════════════════════════
help: ## Show this help
	@echo "═══════════════════════════════════════════════════"
	@echo "  PostgreSQL Service — Makefile (DEV)"
	@echo "═══════════════════════════════════════════════════"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ══════════════════════════════════════════════
# Network Management
# ══════════════════════════════════════════════
network-create: ## Create networks for DEV (idempotent)
	@if ! docker network inspect $(GATEWAY_NETWORK) >/dev/null 2>&1; then \
		echo "Creating gateway network: $(GATEWAY_NETWORK) ($(GATEWAY_SUBNET))"; \
		docker network create --driver bridge --subnet=$(GATEWAY_SUBNET) $(GATEWAY_NETWORK); \
	else \
		echo "Gateway network $(GATEWAY_NETWORK) already exists"; \
	fi
	@if ! docker network inspect $(INTERNAL_NETWORK) >/dev/null 2>&1; then \
		echo "Creating internal network: $(INTERNAL_NETWORK) ($(INTERNAL_SUBNET))"; \
		docker network create --driver bridge --internal --subnet=$(INTERNAL_SUBNET) $(INTERNAL_NETWORK); \
	else \
		echo "Internal network $(INTERNAL_NETWORK) already exists"; \
	fi

network-destroy: ## Destroy networks for DEV
	@docker network rm $(GATEWAY_NETWORK) 2>/dev/null || true
	@docker network rm $(INTERNAL_NETWORK) 2>/dev/null || true

# ══════════════════════════════════════════════
# Lifecycle
# ══════════════════════════════════════════════
up: network-create ## Start postgres
	$(DC) up -d --build
	@echo "✅ $(CONTAINER_NAME) started"

down: ## Stop postgres
	$(DC) down
	@echo "✅ $(CONTAINER_NAME) stopped"

restart: ## Restart postgres
	$(DC) restart
	@echo "✅ $(CONTAINER_NAME) restarted"

logs: ## Tail logs
	$(DC) logs -f --tail=100

shell: ## Open psql shell
	docker exec -it $(CONTAINER_NAME) psql -U $$(grep POSTGRES_USER $(ENV_FILE) | cut -d= -f2) -d $$(grep POSTGRES_DB $(ENV_FILE) | cut -d= -f2)

status: ## Show container status + health
	@echo "═══════════════════════════════════════════════════"
	@echo "  PostgreSQL Status — DEV"
	@echo "═══════════════════════════════════════════════════"
	@docker inspect --format='  Container: {{.Name}}' $(CONTAINER_NAME) 2>/dev/null || echo "  Container: NOT FOUND"
	@docker inspect --format='  State: {{.State.Status}}' $(CONTAINER_NAME) 2>/dev/null || true
	@docker inspect --format='  Health: {{.State.Health.Status}}' $(CONTAINER_NAME) 2>/dev/null || true
	@docker inspect --format='  Started: {{.State.StartedAt}}' $(CONTAINER_NAME) 2>/dev/null || true
	@echo ""
	@echo "  --- Replica ---"
	@docker inspect --format='  Container: {{.Name}}' $(REPLICA_CONTAINER) 2>/dev/null || echo "  Container: NOT FOUND"
	@docker inspect --format='  State: {{.State.Status}}' $(REPLICA_CONTAINER) 2>/dev/null || true
	@docker inspect --format='  Health: {{.State.Health.Status}}' $(REPLICA_CONTAINER) 2>/dev/null || true
	@docker inspect --format='  Started: {{.State.StartedAt}}' $(REPLICA_CONTAINER) 2>/dev/null || true

# ══════════════════════════════════════════════
# Build
# ══════════════════════════════════════════════
build: ## Build the Docker image
	$(DC) build

rebuild: ## Force rebuild (no cache)
	$(DC) build --no-cache

# ══════════════════════════════════════════════
# Operations
# ══════════════════════════════════════════════
backup: ## Backup database
	@for i in $$(seq 1 45); do docker exec $(CONTAINER_NAME) pg_isready -q 2>/dev/null && break; sleep 2; done
	@docker exec $(CONTAINER_NAME) pg_isready -q || (echo "❌ $(CONTAINER_NAME) not ready for backup"; exit 1)
	docker exec $(CONTAINER_NAME) /usr/local/bin/scripts/backup.sh
	@echo "✅ Backup complete for $(CONTAINER_NAME)"

restore: ## Restore from backup (FILE=path required)
	@if [ -z "$(FILE)" ]; then echo "❌ Usage: make restore FILE=<backup_file>"; exit 1; fi
	docker cp $(FILE) $(CONTAINER_NAME):/var/lib/postgresql/backups/restore.sql.gz
	docker exec $(CONTAINER_NAME) bash /usr/local/bin/scripts/restore.sh /var/lib/postgresql/backups/restore.sql.gz

list-backups: ## List available backups (host paths)
	@echo "Available backups for $(CONTAINER_NAME):"
	@ls -1 $(DATA_PATH_BASE)/pg_backups/*.sql.gz 2>/dev/null || echo "  (no backups found)"

# ══════════════════════════════════════════════
# Cleanup
# ══════════════════════════════════════════════
clean: ## Remove container + volume
	$(DC) down -v
	@echo "✅ $(CONTAINER_NAME) and volumes removed"
