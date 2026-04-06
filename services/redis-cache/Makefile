# ═══════════════════════════════════════════════════════════════
# Redis Cache Service — Dev Environment Makefile
# ═══════════════════════════════════════════════════════════════

.PHONY: help up down restart logs shell status \
        build rebuild clean network-create network-destroy

export APP_ENV := dev

# ── Derived variables ──
COMPOSE_FILE     := compose/docker-compose.yml
ENV_FILE         := env/dev.env
PROJECT_NAME     := rc-dev
CONTAINER_NAME   := redis-cache-dev
GATEWAY_NETWORK  := gateway_dev_network
INTERNAL_NETWORK := rc_internal_dev

# ── Paths ──
export DATA_PATH_BASE := /root/Desktop/docker-infra-data/dev/redis-cache

# ── Network Config ──
GATEWAY_SUBNET  := 172.20.0.0/24
INTERNAL_SUBNET := 172.20.2.0/28

# Common docker compose command
DC := docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(PROJECT_NAME)

# ══════════════════════════════════════════════
# Help
# ══════════════════════════════════════════════
help: ## Show this help
	@echo "═══════════════════════════════════════════════════"
	@echo "  Redis Cache Service — Makefile (DEV)"
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
up: network-create ## Start redis-cache
	$(DC) up -d --build
	@echo "✅ $(CONTAINER_NAME) started"

down: ## Stop redis-cache
	$(DC) down
	@echo "✅ $(CONTAINER_NAME) stopped"

restart: ## Restart redis-cache
	$(DC) restart
	@echo "✅ $(CONTAINER_NAME) restarted"

logs: ## Tail logs
	$(DC) logs -f --tail=100

shell: ## Open redis-cli shell
	@PASS=$$(grep REDIS_PASSWORD $(ENV_FILE) | cut -d= -f2); \
	if [ -n "$$PASS" ]; then \
		docker exec -it $(CONTAINER_NAME) redis-cli -a "$$PASS" --no-auth-warning; \
	else \
		docker exec -it $(CONTAINER_NAME) redis-cli; \
	fi

status: ## Show container status + health
	@echo "═══════════════════════════════════════════════════"
	@echo "  Redis Cache Status — DEV"
	@echo "═══════════════════════════════════════════════════"
	@docker inspect --format='  Container: {{.Name}}' $(CONTAINER_NAME) 2>/dev/null || echo "  Container: NOT FOUND"
	@docker inspect --format='  State: {{.State.Status}}' $(CONTAINER_NAME) 2>/dev/null || true
	@docker inspect --format='  Health: {{.State.Health.Status}}' $(CONTAINER_NAME) 2>/dev/null || true
	@docker inspect --format='  Started: {{.State.StartedAt}}' $(CONTAINER_NAME) 2>/dev/null || true

# ══════════════════════════════════════════════
# Build
# ══════════════════════════════════════════════
build: ## Build the Docker image
	$(DC) build

rebuild: ## Force rebuild (no cache)
	$(DC) build --no-cache

# ══════════════════════════════════════════════
# Cleanup
# ══════════════════════════════════════════════
clean: ## Remove container + volume
	$(DC) down -v
	@echo "✅ $(CONTAINER_NAME) and volumes removed"
