# ═══════════════════════════════════════════════════════════════
# MinIO Service — Dev Environment Makefile
# ═══════════════════════════════════════════════════════════════

.PHONY: help up down restart logs status shell build clean

export APP_ENV := dev

# ── Derived variables ──
COMPOSE_FILE     := compose/docker-compose.yml
ENV_FILE         := env/dev.env
PROJECT_NAME     := minio-dev
CONTAINER_NAME   := minio-dev
GATEWAY_NETWORK  := gateway_dev_network
INTERNAL_NETWORK := minio_internal_dev

# ── Paths ──
export DATA_PATH_BASE := /root/Desktop/docker-infra-data/dev/minio

# ── Network Config ──
GATEWAY_SUBNET  := 172.20.0.0/24
INTERNAL_SUBNET := 172.20.8.0/28

# Common docker compose command
DC := docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) -p $(PROJECT_NAME)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

network-create: ## Create networks (idempotent)
	@if ! docker network inspect $(GATEWAY_NETWORK) >/dev/null 2>&1; then \
		docker network create --driver bridge --subnet=$(GATEWAY_SUBNET) $(GATEWAY_NETWORK); \
	fi
	@if ! docker network inspect $(INTERNAL_NETWORK) >/dev/null 2>&1; then \
		docker network create --driver bridge --internal --subnet=$(INTERNAL_SUBNET) $(INTERNAL_NETWORK); \
	fi

up: network-create ## Start minio
	$(DC) up -d --build
	@echo "✅ $(CONTAINER_NAME) started"

down: ## Stop minio
	$(DC) down
	@echo "✅ $(CONTAINER_NAME) stopped"

restart: ## Restart minio
	$(DC) restart

logs: ## Tail logs
	$(DC) logs -f --tail=100

status: ## Show container status
	@docker inspect --format='  Container: {{.Name}} [{{.State.Status}}]' $(CONTAINER_NAME) 2>/dev/null || echo "  Container: NOT FOUND"

shell: ## Open mc shell
	docker exec -it $(PROJECT_NAME)-minio-init-1 /bin/sh

clean: ## Remove container + volume
	$(DC) down -v
