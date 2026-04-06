# ═══════════════════════════════════════════════════════════════
# INFRASTRUCTURE — Dedicated Dev Environment
# Dedicated repository for local development
# ═══════════════════════════════════════════════════════════════

.PHONY: help \
    networks-create networks-destroy networks-list \
    env-up env-down env-restart env-status env-logs \
    postgres-up postgres-down postgres-restart postgres-logs postgres-shell postgres-status postgres-backup postgres-restore \
    redis-cache-up redis-cache-down redis-cache-restart redis-cache-logs redis-cache-shell redis-cache-status \
    redis-pubsub-up redis-pubsub-down redis-pubsub-restart redis-pubsub-logs redis-pubsub-shell redis-pubsub-status \
    rabbitmq-up rabbitmq-down rabbitmq-restart rabbitmq-logs rabbitmq-shell rabbitmq-status rabbitmq-backup rabbitmq-restore \
    mailpit-up mailpit-down mailpit-restart mailpit-logs mailpit-status \
    minio-up minio-down minio-restart minio-logs minio-status minio-shell \
    failover-check \
    clean prune

SERVICES_DIR := services
NETWORKS_DIR := networks
ORCHESTRATOR_DIR := orchestrator

# ══════════════════════════════════════════════
# Help
# ══════════════════════════════════════════════
help: ## Show available targets
	@echo "╔═══════════════════════════════════════════════════════════════╗"
	@echo "║   INFRASTRUCTURE — Dedicated Dev Environment                  ║"
	@echo "╚═══════════════════════════════════════════════════════════════╝"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2}'

# ══════════════════════════════════════════════
# Network Management
# ══════════════════════════════════════════════
networks-create: ## Create networks for DEV
	@$(NETWORKS_DIR)/create-networks.sh

networks-destroy: ## Destroy networks for DEV
	@$(NETWORKS_DIR)/destroy-networks.sh

networks-list: ## List all project networks
	@$(NETWORKS_DIR)/list-networks.sh

# ══════════════════════════════════════════════
# Environment Operations
# ══════════════════════════════════════════════
env-up: ## Start all dev services
	@$(ORCHESTRATOR_DIR)/start-all.sh

env-down: ## Stop all dev services
	@$(ORCHESTRATOR_DIR)/stop-all.sh

env-restart: ## Restart all dev services
	@$(ORCHESTRATOR_DIR)/stop-all.sh
	@$(ORCHESTRATOR_DIR)/start-all.sh

env-status: ## Show status for all dev services
	@$(ORCHESTRATOR_DIR)/status.sh

env-logs: ## Show logs for all dev services
	@$(ORCHESTRATOR_DIR)/logs.sh all

# ══════════════════════════════════════════════
# PostgreSQL
# ══════════════════════════════════════════════
postgres-up: ## Start postgres
	@$(MAKE) -C $(SERVICES_DIR)/postgres up

postgres-down: ## Stop postgres
	@$(MAKE) -C $(SERVICES_DIR)/postgres down

postgres-restart: ## Restart postgres
	@$(MAKE) -C $(SERVICES_DIR)/postgres restart

postgres-logs: ## Tail postgres logs
	@$(MAKE) -C $(SERVICES_DIR)/postgres logs

postgres-shell: ## Open psql shell
	@$(MAKE) -C $(SERVICES_DIR)/postgres shell

postgres-status: ## Show postgres status
	@$(MAKE) -C $(SERVICES_DIR)/postgres status

postgres-backup: ## Backup postgres
	@$(MAKE) -C $(SERVICES_DIR)/postgres backup

postgres-restore: ## Restore postgres (FILE= required)
	@$(MAKE) -C $(SERVICES_DIR)/postgres restore FILE=$(FILE)

# ══════════════════════════════════════════════
# Redis Cache
# ══════════════════════════════════════════════
redis-cache-up: ## Start redis-cache
	@$(MAKE) -C $(SERVICES_DIR)/redis-cache up

redis-cache-down: ## Stop redis-cache
	@$(MAKE) -C $(SERVICES_DIR)/redis-cache down

redis-cache-restart: ## Restart redis-cache
	@$(MAKE) -C $(SERVICES_DIR)/redis-cache restart

redis-cache-logs: ## Tail redis-cache logs
	@$(MAKE) -C $(SERVICES_DIR)/redis-cache logs

redis-cache-shell: ## Open redis-cli
	@$(MAKE) -C $(SERVICES_DIR)/redis-cache shell

redis-cache-status: ## Show redis-cache status
	@$(MAKE) -C $(SERVICES_DIR)/redis-cache status

# ══════════════════════════════════════════════
# Redis Pub/Sub
# ══════════════════════════════════════════════
redis-pubsub-up: ## Start redis-pubsub
	@$(MAKE) -C $(SERVICES_DIR)/redis-pubsub up

redis-pubsub-down: ## Stop redis-pubsub
	@$(MAKE) -C $(SERVICES_DIR)/redis-pubsub down

redis-pubsub-restart: ## Restart redis-pubsub
	@$(MAKE) -C $(SERVICES_DIR)/redis-pubsub restart

redis-pubsub-logs: ## Tail redis-pubsub logs
	@$(MAKE) -C $(SERVICES_DIR)/redis-pubsub logs

redis-pubsub-shell: ## Open redis-cli
	@$(MAKE) -C $(SERVICES_DIR)/redis-pubsub shell

redis-pubsub-status: ## Show redis-pubsub status
	@$(MAKE) -C $(SERVICES_DIR)/redis-pubsub status

# ══════════════════════════════════════════════
# RabbitMQ
# ══════════════════════════════════════════════
rabbitmq-up: ## Start rabbitmq
	@$(MAKE) -C $(SERVICES_DIR)/rabbitmq up

rabbitmq-down: ## Stop rabbitmq
	@$(MAKE) -C $(SERVICES_DIR)/rabbitmq down

rabbitmq-restart: ## Restart rabbitmq
	@$(MAKE) -C $(SERVICES_DIR)/rabbitmq restart

rabbitmq-logs: ## Tail rabbitmq logs
	@$(MAKE) -C $(SERVICES_DIR)/rabbitmq logs

rabbitmq-shell: ## Open rabbitmq shell
	@$(MAKE) -C $(SERVICES_DIR)/rabbitmq shell

rabbitmq-status: ## Show rabbitmq status
	@$(MAKE) -C $(SERVICES_DIR)/rabbitmq status

rabbitmq-backup: ## Backup rabbitmq
	@$(MAKE) -C $(SERVICES_DIR)/rabbitmq backup

rabbitmq-restore: ## Restore rabbitmq (FILE= required)
	@$(MAKE) -C $(SERVICES_DIR)/rabbitmq restore FILE=$(FILE)

# ══════════════════════════════════════════════
# Mailpit
# ══════════════════════════════════════════════
mailpit-up: ## Start mailpit
	@$(MAKE) -C $(SERVICES_DIR)/mailpit up

mailpit-down: ## Stop mailpit
	@$(MAKE) -C $(SERVICES_DIR)/mailpit down

mailpit-restart: ## Restart mailpit
	@$(MAKE) -C $(SERVICES_DIR)/mailpit restart

mailpit-logs: ## Tail mailpit logs
	@$(MAKE) -C $(SERVICES_DIR)/mailpit logs

mailpit-status: ## Show mailpit status
	@$(MAKE) -C $(SERVICES_DIR)/mailpit status

# ══════════════════════════════════════════════
# MinIO
# ══════════════════════════════════════════════
minio-up: ## Start minio
	@$(MAKE) -C $(SERVICES_DIR)/minio up

minio-down: ## Stop minio
	@$(MAKE) -C $(SERVICES_DIR)/minio down

minio-restart: ## Restart minio
	@$(MAKE) -C $(SERVICES_DIR)/minio restart

minio-logs: ## Tail minio logs
	@$(MAKE) -C $(SERVICES_DIR)/minio logs

minio-status: ## Show minio status
	@$(MAKE) -C $(SERVICES_DIR)/minio status

minio-shell: ## Open minio mc shell
	@$(MAKE) -C $(SERVICES_DIR)/minio shell

# ══════════════════════════════════════════════
# Validation
# ══════════════════════════════════════════════
failover-check: ## Stop/start each service and verify others stay up (dev)
	@$(ORCHESTRATOR_DIR)/failover-check.sh

# ══════════════════════════════════════════════
# Cleanup
# ══════════════════════════════════════════════
clean: ## Remove containers + volumes for DEV
	@$(MAKE) -C $(SERVICES_DIR)/postgres clean
	@$(MAKE) -C $(SERVICES_DIR)/redis-cache clean
	@$(MAKE) -C $(SERVICES_DIR)/redis-pubsub clean
	@$(MAKE) -C $(SERVICES_DIR)/rabbitmq clean
	@$(MAKE) -C $(SERVICES_DIR)/mailpit clean
	@$(MAKE) -C $(SERVICES_DIR)/minio clean

prune: ## Docker system prune
	docker system prune -f
	docker volume prune -f
