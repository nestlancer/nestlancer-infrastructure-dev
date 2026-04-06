# Infrastructure Architecture - DEV Environment

> **Last updated:** 2026-04-04  
> **Project:** Nestlancer Infrastructure - Development Environment  
> **Purpose:** Local development and rapid iteration

---

## Table of Contents

1. [DEV Environment Overview](#1-dev-environment-overview)
2. [Container Inventory (7 Containers)](#2-container-inventory-7-containers)
3. [Port Mapping (Host → Container)](#3-port-mapping-host--container)
4. [Network Architecture](#4-network-architecture)
5. [Volume & Data Persistence](#5-volume--data-persistence)
6. [Security Configuration](#6-security-configuration)
7. [Health Checks](#7-health-checks)
8. [Resource Limits](#8-resource-limits)
9. [Compose File Strategy](#9-compose-file-strategy)
10. [Service Catalog](#10-service-catalog)
11. [Development Workflow](#11-development-workflow)
12. [Makefile Commands](#12-makefile-commands)
13. [Directory Structure](#13-directory-structure)

---

## 1. DEV Environment Overview

The development environment provides a **full-featured local development stack** with 7 containers running on a single Docker host. This environment prioritizes developer experience with exposed ports, verbose logging, and minimal security restrictions.

```
┌─────────────────────────────────────────────────────────────────────┐
│                     DEV ENVIRONMENT (172.20.x.x)                    │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────┐     │
│  │                  7 Development Containers                   │     │
│  │                                                             │     │
│  │  • postgres-dev           (Primary Database)               │     │
│  │  • postgres-replica-dev   (Read Replica)                   │     │
│  │  • redis-cache-dev        (Application Cache)              │     │
│  │  • redis-pubsub-dev       (Real-time Messaging)            │     │
│  │  • rabbitmq-dev           (Message Queue)                  │     │
│  │  • mailpit-dev            (Email Testing)                  │     │
│  │  • minio-dev              (Object Storage)                 │     │
│  │                                                             │     │
│  └─────────────────┬───────────────────────────────────────────┘     │
│                    │                                                 │
│         Connected via gateway_dev_network (172.20.0.0/24)           │
│         ALL PORTS EXPOSED to localhost for easy development         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Characteristics

| Property | Value |
|:---|:---|
| **Total Containers** | 7 |
| **Gateway Subnet** | `172.20.0.0/24` |
| **Host Port Exposure** | ✅ All services exposed |
| **Restart Policy** | `unless-stopped` |
| **Resource Limits** | ❌ None |
| **Security Hardening** | ❌ Minimal |
| **Logging Level** | `verbose` / `debug` |
| **Read-Only Rootfs** | ❌ No |
| **Email capture** | ✅ Mailpit (SMTP + Web UI) |
| **Object Storage** | ✅ MinIO (S3-compatible) |

---

## 2. Container Inventory (7 Containers)

| # | Container Name | Service | Image | Purpose |
|:---:|:---|:---|:---|:---|
| 1 | `postgres-dev` | PostgreSQL Primary | Custom | Primary relational database |
| 2 | `postgres-replica-dev` | PostgreSQL Replica | Custom | Read-only replica (local dev) |
| 3 | `redis-cache-dev` | Redis Cache | Custom | Application caching layer |
| 4 | `redis-pubsub-dev` | Redis Pub/Sub | Custom | Real-time event messaging |
| 5 | `rabbitmq-dev` | RabbitMQ | Custom | Durable message queue |
| 6 | `mailpit-dev` | Mailpit | `axllent/mailpit:latest` | Email testing (SMTP trap) |
| 7 | `minio-dev` | MinIO | `quay.io/minio/minio:latest` | S3-compatible object storage |

---

## 3. Port Mapping (Host → Container)

All services expose ports to `localhost` for easy development access.

| Service | Host Port | Container Port | Protocol | Access URL / Connection String |
|:---|:---:|:---:|:---|:---|
| **PostgreSQL Primary** | `5432` | `5432` | TCP | `localhost:5432` |
| **PostgreSQL Replica** | `5433` | `5432` | TCP | `localhost:5433` |
| **Redis Cache** | `6379` | `6379` | TCP | `localhost:6379` |
| **Redis Pub/Sub** | `6380` | `6379` | TCP | `localhost:6380` |
| **RabbitMQ AMQP** | `5672` | `5672` | TCP | `localhost:5672` |
| **RabbitMQ Management UI** | `15672` | `15672` | HTTP | `http://localhost:15672` |
| **RabbitMQ Prometheus** | `15692` | `15692` | HTTP | `http://localhost:15692/metrics` |
| **Mailpit SMTP** | `1025` | `1025` | TCP | `localhost:1025` |
| **Mailpit Web UI** | `8025` | `8025` | HTTP | `http://localhost:8025` |
| **MinIO API** | `9000` | `9000` | HTTP | `http://localhost:9000` |
| **MinIO Console** | `9001` | `9001` | HTTP | `http://localhost:9001` |

### Quick Access Links

```bash
# RabbitMQ Management UI
open http://localhost:15672
# Default credentials: nl_infra_admin / <from env file>

# Mailpit Email Viewer
open http://localhost:8025

# MinIO Console
open http://localhost:9001
# Default credentials: nl_admin / <from env file>
```

---

## 4. Network Architecture

### 4.1 Network Topology

```
                    ┌─────────────────────────────────────┐
                    │    gateway_dev_network              │
                    │    172.20.0.0/24                    │
                    │    (all containers attach here)     │
                    └─┬────┬────┬────┬────┬────┬────┬────┘
                      │    │    │    │    │    │    │
              ┌───────┴┐┌──┴──┐┌┴───┐┌┴───┐┌┴───┐┌┴──┐
              │postgres││redis││redis││rmq ││mail││min│
              │+replica││cache││pub/ ││    ││pit ││io │
              │        ││     ││sub  ││    ││    ││   │
              └────┬───┘└──┬──┘└┬───┘└┬───┘└┬───┘└┬──┘
                   │       │    │     │     │     │
              ┌────┴───┐┌──┴──┐┌┴───┐┌┴───┐┌┴───┐┌┴──┐
              │pg_int_ ││rc_  ││rp_ ││rmq_││mail││min│
              │dev     ││int_ ││int_││int_││int_││int│
              │(int.)  ││dev  ││dev ││dev ││dev ││io │
              └────────┘└─────┘└────┘└────┘└────┘└───┘
```

### 4.2 Network Inventory

| # | Network Name | Subnet | Driver | Internal | Connected Services |
|:---:|:---|:---|:---|:---:|:---|
| 1 | `gateway_dev_network` | `172.20.0.0/24` | bridge | ❌ No | All 7 containers |
| 2 | `pg_internal_dev` | `172.20.1.0/28` | bridge | ✅ Yes | postgres-dev, postgres-replica-dev |
| 3 | `rc_internal_dev` | `172.20.2.0/28` | bridge | ✅ Yes | redis-cache-dev |
| 4 | `rp_internal_dev` | `172.20.3.0/28` | bridge | ✅ Yes | redis-pubsub-dev |
| 5 | `rmq_internal_dev` | `172.20.4.0/28` | bridge | ✅ Yes | rabbitmq-dev |
| 6 | `mailpit_internal_dev` | `172.20.7.0/28` | bridge | ✅ Yes | mailpit-dev |
| 7 | `minio_internal_dev` | `172.20.8.0/28` | bridge | ✅ Yes | minio-dev |

### 4.3 Static IP Assignments

| Container | Network | Static IP |
|:---|:---|:---|
| `postgres-dev` | `pg_internal_dev` | `172.20.1.2` |
| `postgres-replica-dev` | `pg_internal_dev` | `172.20.1.3` |
| `mailpit-dev` | `mailpit_internal_dev` | `172.20.7.2` |
| `minio-dev` | `minio_internal_dev` | `172.20.8.2` |

### 4.4 Network Creation

```bash
# Create all dev networks
cd nestlancer-infrastructure-dev/networks
./create-networks.sh

# Or from the repository root
make networks-create
```

---

## 5. Volume & Data Persistence

All persistent data is stored under:

```
/root/Desktop/docker-infra-data/dev/{service}/
```

### 5.1 Data Volume Map

| Service | Host Path | Container Path | Purpose |
|:---|:---|:---|:---|
| **PostgreSQL Primary** | `{BASE}/dev/postgres/pg_data` | `/var/lib/postgresql/data` | Primary database files |
| **PostgreSQL Replica** | `{BASE}/dev/postgres/pg_replica_data` | `/var/lib/postgresql/data` | Replica database files |
| **PostgreSQL Backups** | `{BASE}/dev/postgres/pg_backups` | `/var/lib/postgresql/backups` | Backup storage |
| **Redis Cache** | `{BASE}/dev/redis-cache/rc_data` | `/data` | RDB/AOF persistence files |
| **Redis Pub/Sub** | `{BASE}/dev/redis-pubsub/rp_data` | `/data` | Data directory (ephemeral) |
| **RabbitMQ Data** | `{BASE}/dev/rabbitmq/rmq_data` | `/var/lib/rabbitmq` | Queue data + Mnesia DB |
| **RabbitMQ Backups** | `{BASE}/dev/rabbitmq/rmq_backups` | `/var/lib/rabbitmq/backups` | Backup storage |
| **MinIO Data** | `{BASE}/dev/minio/minio_data` | `/data` | Object storage buckets |

### 5.2 Read-Only Config Mounts

| Service | Host Path | Container Path | Mode |
|:---|:---|:---|:---|
| **PostgreSQL** | `config/base/postgresql.conf` | `/etc/postgresql/base.conf` | `ro` |
| **PostgreSQL** | `config/dev/postgresql.conf` | `/etc/postgresql/override.conf` | `ro` |
| **PostgreSQL** | `config/base/pg_hba.conf` | `/etc/postgresql/base_hba.conf` | `ro` |
| **PostgreSQL** | `config/dev/pg_hba.conf` | `/etc/postgresql/override_hba.conf` | `ro` |
| **PostgreSQL** | `init/*.sh` | `/docker-entrypoint-initdb.d/` | `ro` |
| **Redis Cache** | `config/base/redis.conf` | `/etc/redis/base.conf` | `ro` |
| **Redis Cache** | `config/dev/redis.conf` | `/etc/redis/override.conf` | `ro` |
| **Redis Pub/Sub** | `config/base/redis.conf` | `/etc/redis/base.conf` | `ro` |
| **Redis Pub/Sub** | `config/dev/redis.conf` | `/etc/redis/override.conf` | `ro` |
| **RabbitMQ** | `config/base/rabbitmq.conf` | `/etc/rabbitmq/rabbitmq.conf` | `ro` |
| **RabbitMQ** | `config/dev/rabbitmq.conf` | `/etc/rabbitmq/conf.d/10-override.conf` | `ro` |
| **MinIO** | `init/setup.sh` | `/setup.sh` | `ro` |

---

## 6. Security Configuration

The DEV environment uses **minimal security** to maximize developer flexibility.

### 6.1 Security Settings

| Feature | Status | Notes |
|:---|:---:|:---|
| **Read-Only Rootfs** | ❌ Disabled | Full write access for debugging |
| **Capability Dropping** | ❌ Disabled | All capabilities available |
| **No-New-Privileges** | ❌ Disabled | Allows privilege escalation for debugging |
| **Tmpfs Mounts** | ❌ Not used | Write directly to container filesystem |
| **Host Port Exposure** | ✅ **Enabled** | All services exposed to localhost |
| **Firewall Rules** | ❌ Not enforced | Open access from host |
| **Log Rotation** | ❌ Not configured | Uses Docker defaults |

### 6.2 Container Security Profile

```yaml
# Typical DEV container security (PostgreSQL example)
services:
  postgres:
    # NO read_only
    # NO tmpfs
    # NO security_opt
    # NO cap_drop
    # NO cap_add restrictions
    
    # Full access for development
    restart: unless-stopped
    ports:
      - "5432:5432"  # EXPOSED to host
```

### 6.3 Network Security

```bash
# Internal networks block internet access
# but gateway_dev_network allows outbound connections
```

### 6.4 Credential Management

**Default credentials (local development only):**

```bash
# PostgreSQL
POSTGRES_USER=nl_infra_admin
POSTGRES_PASSWORD=DevOnly_SecurePass123!

# Redis Cache
REDIS_PASSWORD=DevOnly_Redis_Cache_Pass123!

# Redis Pub/Sub
REDIS_PASSWORD=DevOnly_Redis_PubSub_Pass123!

# RabbitMQ
RABBITMQ_DEFAULT_USER=nl_infra_admin
RABBITMQ_DEFAULT_PASS=DevOnly_RabbitMQ_Pass123!

# MinIO
MINIO_ROOT_USER=nl_admin
MINIO_ROOT_PASSWORD=DevOnly_MinIO_Admin_Pass123!
```

> **⚠️ WARNING:** These credentials are for local development only. Do not reuse them elsewhere.

---

## 7. Health Checks

All services have health checks with **relaxed timings** for development.

### 7.1 Health Check Configuration

| Service | Test Command | Interval | Timeout | Retries | Start Period |
|:---|:---|:---:|:---:|:---:|:---:|
| **PostgreSQL** | `/usr/local/bin/healthcheck.sh` | `30s` | `10s` | `5` | `30s` |
| **Redis Cache** | `/usr/local/bin/healthcheck.sh` | `30s` | `10s` | `5` | `10s` |
| **Redis Pub/Sub** | `/usr/local/bin/healthcheck.sh` | `30s` | `10s` | `5` | `10s` |
| **RabbitMQ** | `/usr/local/bin/healthcheck.sh` | `30s` | `10s` | `5` | `30s` |
| **Mailpit** | (image default) | — | — | — | — |
| **MinIO** | `curl -f http://localhost:9000/minio/health/live` | `30s` | `10s` | `5` | Default |

### 7.2 Check Container Health

```bash
# Check all DEV container health
make status
# Or using orchestrator
cd orchestrator
./status.sh

# Docker native
docker ps --filter "name=dev" --format "table {{.Names}}\t{{.Status}}"
```

---

## 8. Resource Limits

The dev stack has **no resource limits** by default.

### 8.1 Services (no limits)

| Service | CPU Limit | Memory Limit | Reservation |
|:---|:---|:---|:---|
| **PostgreSQL** | ∞ | ∞ | None |
| **PostgreSQL Replica** | ∞ | ∞ | None |
| **Redis Cache** | ∞ | ∞ | None |
| **Redis Pub/Sub** | ∞ | ∞ | None |
| **RabbitMQ** | ∞ | ∞ | None |
| **Mailpit** | ∞ | ∞ | None |
| **MinIO** | ∞ | ∞ | None |

### 8.2 Monitoring resource usage

```bash
cd nestlancer-infrastructure-dev/scripts
./monitor-containers.sh --duration 60 --out-dir /tmp/infra-reports
```

---

## 9. Compose layout

This repository is **dev-only**: each service has a single compose file plus `env/dev.env`.

```
services/{service}/compose/docker-compose.yml
services/{service}/env/dev.env
```

### 9.1 Typical invocation

```bash
docker compose \
  -f compose/docker-compose.yml \
  --env-file env/dev.env \
  -p {service}-dev \
  up -d --build
```

(Service `Makefile`s wrap the above with the correct project name and paths.)

### 9.2 Project and container names

| Service | Compose project | Container name(s) |
|:---|:---|:---|
| PostgreSQL | `pg-dev` | `postgres-dev`, `postgres-replica-dev` |
| Redis Cache | `rc-dev` | `redis-cache-dev` |
| Redis Pub/Sub | `rp-dev` | `redis-pubsub-dev` |
| RabbitMQ | `rmq-dev` | `rabbitmq-dev` |
| Mailpit | `mailpit-dev` | `mailpit-dev` |
| MinIO | `minio-dev` | `minio-dev` |

---

## 10. Service Catalog

### 10.1 PostgreSQL

**Image:** Custom (`services/postgres/docker/Dockerfile`)

```yaml
Container Port: 5432
Host Port: 5432 (primary), 5433 (replica)
Database Names: nl_maintenance_dev, nl_platform_dev
Users Created:
  - nl_infra_admin (superuser)
  - nl_platform_app (app user)
  - nl_analytics_readonly (read-only)
  - nl_replication_service (replication)

Config:
  - Shared memory: 1GB
  - Max connections: 100
  - Logging: verbose
  - WAL level: replica (for replication)
```

**Key Directories:**
```
services/postgres/
├── init/
│   ├── 00-config.sh              # Merges base + dev config
│   ├── 01-create-databases.sh    # Creates nl_maintenance_dev, nl_platform_dev
│   ├── 02-create-users.sh        # Creates all users with grants
│   └── 03-extensions.sh          # Installs pg extensions
├── config/
│   ├── base/postgresql.conf      # Base PostgreSQL config
│   ├── dev/postgresql.conf       # DEV overrides (verbose logging)
│   ├── base/pg_hba.conf          # Base auth rules
│   └── dev/pg_hba.conf           # DEV auth rules (permissive)
└── scripts/
    ├── healthcheck.sh            # Health check script
    └── backup.sh                 # Manual backup script
```

**Connection String:**
```bash
# Primary
postgresql://nl_platform_app:password@localhost:5432/nl_platform_dev

# Replica (read-only)
postgresql://nl_platform_app:password@localhost:5433/nl_platform_dev
```

### 10.2 Redis Cache

**Image:** Custom (`services/redis-cache/docker/Dockerfile`)

```yaml
Container Port: 6379
Host Port: 6379
Role: Application caching (session, query cache, etc.)

Config:
  - Max memory: 256MB
  - Eviction policy: allkeys-lru
  - Persistence: RDB + AOF
  - Log level: verbose
  - Requirepass: DevOnly_Redis_Cache_Pass123!
```

**Connection:**
```bash
redis-cli -h localhost -p 6379 -a DevOnly_Redis_Cache_Pass123!
```

### 10.3 Redis Pub/Sub

**Image:** Custom (`services/redis-pubsub/docker/Dockerfile`)

```yaml
Container Port: 6379
Host Port: 6380
Role: Real-time pub/sub messaging

Config:
  - Max memory: 128MB
  - Persistence: RDB (but pub/sub is ephemeral)
  - Log level: verbose
  - Requirepass: DevOnly_Redis_PubSub_Pass123!
```

**Connection:**
```bash
redis-cli -h localhost -p 6380 -a DevOnly_Redis_PubSub_Pass123!
```

### 10.4 RabbitMQ

**Image:** Custom (`services/rabbitmq/docker/Dockerfile`)

```yaml
Container Ports: 5672 (AMQP), 15672 (Management), 15692 (Prometheus)
Host Ports: 5672, 15672, 15692
Role: Durable message queue

Config:
  - Node name: rabbit@rabbitmq-dev
  - Plugins: management, prometheus, shovel, federation
  - Credentials: nl_infra_admin / DevOnly_RabbitMQ_Pass123!
```

**Access:**
```bash
# Management UI
http://localhost:15672

# AMQP Connection
amqp://nl_infra_admin:DevOnly_RabbitMQ_Pass123!@localhost:5672

# Prometheus Metrics
http://localhost:15692/metrics
```

### 10.5 Mailpit (Email Testing)

**Image:** `axllent/mailpit:latest`

```yaml
Container Ports: 1025 (SMTP), 8025 (Web UI)
Host Ports: 1025, 8025
Role: SMTP trap for testing emails

Config:
  - Max messages: 1000
  - No persistence (in-memory only)
  - Web UI access: http://localhost:8025
```

**Usage in Your App:**
```bash
# SMTP Settings
MAIL_HOST=localhost
MAIL_PORT=1025
MAIL_ENCRYPTION=null
MAIL_USERNAME=null
MAIL_PASSWORD=null

# All emails sent to localhost:1025 appear in http://localhost:8025
```

### 10.6 MinIO (Object Storage)

**Image:** `quay.io/minio/minio:latest`

```yaml
Container Ports: 9000 (API), 9001 (Console)
Host Ports: 9000, 9001
Role: S3-compatible local object storage

Config:
  - Root user: nl_admin
  - Root password: DevOnly_MinIO_Admin_Pass123!
  - Auto-creates 8 buckets on startup
  - Console: http://localhost:9001
```

**Auto-Created Buckets:**
```
nl-dev-media-private
nl-dev-media-public
nl-dev-user-avatars
nl-dev-service-requests
nl-dev-sales-quotes
nl-dev-project-outputs
nl-dev-admin-reports
nl-dev-billing-receipts
```

**S3 configuration (for your app):**
```bash
AWS_ACCESS_KEY_ID=nl_service_account
AWS_SECRET_ACCESS_KEY=<generated on first start, see container logs>
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=nl-dev-media-private
AWS_ENDPOINT=http://localhost:9000
AWS_USE_PATH_STYLE_ENDPOINT=true
```

---

## 11. Development Workflow

### 11.1 Initial Setup

```bash
# Clone repository
git clone <repo-url>
cd nestlancer-infrastructure-dev

# Create all DEV networks
make networks-create
# Start all DEV services
make env-up
# Check status
make env-status
```

### 11.2 Daily Operations

**Start everything:**
```bash
make env-up
```

**Stop everything:**
```bash
make env-down
```

**Check status:**
```bash
make env-status
# or
cd orchestrator && ./status.sh
```

**View logs:**
```bash
# All services
make env-logs
# Specific service
make postgres-logs
make redis-cache-logs
make rabbitmq-logs
```

**Restart a service:**
```bash
make postgres-restart
```

**Shell access:**
```bash
# PostgreSQL
make postgres-shell
# Redis Cache
make redis-cache-shell
# RabbitMQ
make rabbitmq-shell
```

### 11.3 Database Operations

**Connect to PostgreSQL:**
```bash
# Via psql
psql -h localhost -p 5432 -U nl_platform_app -d nl_platform_dev

# Via docker exec
docker exec -it postgres-dev psql -U nl_infra_admin -d nl_platform_dev
```

**Manual backup:**
```bash
make postgres-backup
```

**Restore from Backup:**
```bash
make postgres-restore FILE=/path/to/backup.sql
```

### 11.4 Testing Email Delivery

```bash
# Configure your app to use Mailpit
MAIL_HOST=localhost
MAIL_PORT=1025

# Send test email from your app
# View it at http://localhost:8025
```

### 11.5 Testing Object Storage

```bash
# Access MinIO Console
open http://localhost:9001

# Or use AWS CLI
aws --endpoint-url http://localhost:9000 s3 ls
aws --endpoint-url http://localhost:9000 s3 cp file.txt s3://nl-dev-media-private/
```

### 11.6 Troubleshooting

**Container won't start:**
```bash
# Check logs
docker logs postgres-dev
docker logs --tail 100 -f rabbitmq-dev

# Check health
docker inspect postgres-dev | jq '.[0].State.Health'
```

**Port already in use:**
```bash
# Find what's using the port
lsof -i :5432
sudo ss -tulpn | grep 5432

# Kill the process or change the port in services/<name>/compose/docker-compose.yml
```

**Network issues:**
```bash
# Inspect network
docker network inspect gateway_dev_network

# Test connectivity between containers
docker exec -it postgres-dev ping redis-cache-dev
```

**Reset everything:**
```bash
# Nuclear option: destroy all DEV containers and volumes
make clean
# Then recreate
make networks-create
make env-up
```

---

## 12. Makefile Commands

All commands are run from the root `nestlancer-infrastructure-dev/` directory.

### 12.1 Environment-level commands

```bash
make env-up          # Start all dev services
make env-down        # Stop all dev services
make env-restart     # Restart all dev services
make env-status      # Status dashboard
make env-logs        # Aggregate logs (see orchestrator/logs.sh)
make clean           # Remove containers + volumes per service
make prune           # Docker system / volume prune
make failover-check   # Service isolation check (orchestrator/failover-check.sh)
```

### 12.2 Service-specific commands

**PostgreSQL:**
```bash
make postgres-up
make postgres-down
make postgres-restart
make postgres-logs
make postgres-shell
make postgres-status
make postgres-backup
make postgres-restore FILE=/path/to/backup.sql
```

**Redis Cache:**
```bash
make redis-cache-up
make redis-cache-down
make redis-cache-restart
make redis-cache-logs
make redis-cache-shell
make redis-cache-status
```

**Redis Pub/Sub:**
```bash
make redis-pubsub-up
make redis-pubsub-down
make redis-pubsub-restart
make redis-pubsub-logs
make redis-pubsub-shell
make redis-pubsub-status
```

**RabbitMQ:**
```bash
make rabbitmq-up
make rabbitmq-down
make rabbitmq-restart
make rabbitmq-logs
make rabbitmq-shell
make rabbitmq-status
make rabbitmq-backup
make rabbitmq-restore FILE=/path/to/backup.json
```

**Mailpit:**
```bash
make mailpit-up
make mailpit-down
make mailpit-restart
make mailpit-logs
make mailpit-status
```

**MinIO:**
```bash
make minio-up
make minio-down
make minio-restart
make minio-logs
make minio-status
make minio-shell
```

### 12.3 Network commands

```bash
make networks-create
make networks-destroy
make networks-list
```

### 12.4 Resource monitoring

```bash
./scripts/monitor-containers.sh --duration 60 --out-dir /tmp/infra-reports
```

---

## 13. Directory Structure

```
nestlancer-infrastructure-dev/
├── Makefile
├── architecture-dev.md
│
├── services/
│   ├── postgres/
│   │   ├── Makefile
│   │   ├── compose/docker-compose.yml
│   │   ├── config/base/  config/dev/
│   │   ├── docker/Dockerfile
│   │   ├── env/dev.env
│   │   ├── init/
│   │   └── scripts/
│   ├── redis-cache/       # compose/, config/, docker/, env/, scripts/
│   ├── redis-pubsub/
│   ├── rabbitmq/
│   ├── mailpit/
│   └── minio/
│
├── networks/
│   ├── network-config.yml
│   ├── create-networks.sh
│   ├── destroy-networks.sh
│   └── list-networks.sh
│
├── orchestrator/
│   ├── start-all.sh
│   ├── stop-all.sh
│   ├── destroy-all.sh
│   ├── restart-service.sh
│   ├── status.sh
│   ├── logs.sh
│   └── failover-check.sh
│
└── scripts/
    └── monitor-containers.sh
```

---

## Connection Flow Diagram

```mermaid
graph TB
    subgraph "Developer Machine"
        DEV[Developer<br>localhost]
    end

    subgraph "DEV Environment (172.20.x.x)"
        GW[gateway_dev_network<br>172.20.0.0/24]
        
        PG[postgres-dev<br>:5432]
        PGR[postgres-replica-dev<br>:5433]
        RC[redis-cache-dev<br>:6379]
        RP[redis-pubsub-dev<br>:6380]
        RMQ[rabbitmq-dev<br>:5672,:15672]
        MP[mailpit-dev<br>:1025,:8025]
        MIO[minio-dev<br>:9000,:9001]
        
        GW --- PG
        GW --- PGR
        GW --- RC
        GW --- RP
        GW --- RMQ
        GW --- MP
        GW --- MIO
    end

    DEV -->|All ports exposed<br>to localhost| GW

    style GW fill:#2ecc71,color:#fff
    style DEV fill:#3498db,color:#fff
```

---

## Quick Start Checklist

- [ ] Clone repository
- [ ] Review credentials in `services/*/env/dev.env`
- [ ] Run `make networks-create`
- [ ] Run `make env-up`
- [ ] Wait ~60 seconds for all health checks to pass
- [ ] Run `make env-status`
- [ ] Access RabbitMQ UI: `http://localhost:15672`
- [ ] Access Mailpit UI: `http://localhost:8025`
- [ ] Access MinIO Console: `http://localhost:9001`
- [ ] Connect to PostgreSQL: `psql -h localhost -p 5432 -U nl_platform_app -d nl_platform_dev`
- [ ] Configure your application to use these services
- [ ] Start developing! 🚀

---
