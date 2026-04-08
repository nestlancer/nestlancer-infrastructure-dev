<div align="center">

# Nestlancer Infrastructure — Development

### Seven containers · `172.20.x.x` networks · localhost ports · Mailpit + MinIO

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Linux](https://img.shields.io/badge/Host-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://kernel.org/)


<br/>

**Development-only repo:** PostgreSQL primary + replica, Redis cache, Redis pub/sub, RabbitMQ, Mailpit, and MinIO — orchestrated with **Make**, **Bash**, and **Docker Compose** (single `docker-compose.yml` per service + `env/dev.env`).

<br/>

[Overview](#1-overview--setup) •
[Operations](#2-daily-operations) •
[Backup & restore](#3-backup--restore) •
[Monitoring](#4-monitoring--observability) •
[Localhost & data](#5-localhost-access--data-paths) •
[Reference](#6-reference-dev-only) •
[Troubleshooting](#7-troubleshooting) •
[Security](#8-security-notes-development)

<br/>

---

</div>

<br/>

## Table of contents

<details>
<summary><b>Expand full outline</b></summary>

### Part I — Overview & setup
1. [Overview & setup](#1-overview--setup)
   - [Prerequisites](#11-prerequisites)
   - [Architecture](#12-architecture)
   - [Design principles](#13-design-principles)
   - [Directory structure](#14-directory-structure)
   - [Quick start](#15-quick-start)
2. [Daily operations](#2-daily-operations)
   - [Root Makefile](#21-root-makefile--primary-interface)
   - [Service-level commands](#22-service-level-commands)
   - [Orchestrator scripts](#23-orchestrator-scripts)
   - [Network management](#24-network-management)
   - [Failover check](#25-failover-check)
3. [Backup & restore](#3-backup--restore)
4. [Monitoring & observability](#4-monitoring--observability)
5. [Localhost access & data paths](#5-localhost-access--data-paths)
6. [Reference (dev only)](#6-reference-dev-only)
7. [Troubleshooting](#7-troubleshooting)
8. [Security notes (development)](#8-security-notes-development)

</details>

---

# 1. Overview & setup

> **Scope:** This repository defines **one** environment: **local development**. Services publish **host ports** for convenient access from your workstation. There is no production override compose, Tailscale automation, or cloud backup wiring in-tree.

---

## 1.1 Prerequisites

| Requirement | Minimum | Check |
|:------------|:--------|:------|
| Docker Engine | 24+ | `docker --version` |
| Docker Compose | v2+ | `docker compose version` |
| GNU Make | 4+ | `make --version` |
| Bash | 4+ | `bash --version` |

Run all examples from the **`nestlancer-infrastructure-dev/`** root unless noted otherwise.

---

## 1.2 Architecture

Single Docker host: **seven** containers on **`172.20.x.x`**, attached to **`gateway_dev_network`** (`172.20.0.0/24`) and each service’s **internal `/28`** where applicable. **Host ports are published** — use `localhost` (see [§6.4](#64-host-ports-localhost)).

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DEVELOPMENT DOCKER HOST                              │
│                                                                             │
│   ┌─── DEV (172.20.x.x) ───────────────────────────────────────────────────┐ │
│   │  postgres-dev / postgres-replica-dev    redis-cache-dev              │ │
│   │  redis-pubsub-dev    rabbitmq-dev        mailpit-dev    minio-dev      │ │
│   │  Gateway: gateway_dev_network  +  per-service internal networks         │ │
│   │  Host ports: YES — localhost (PostgreSQL, Redis, RMQ, Mailpit, MinIO)  │ │
│   └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│   Data root (typical): /root/Desktop/docker-infra-data/dev/<service>/        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 1.3 Design principles

| Principle | Implementation |
|:----------|:---------------|
| **Developer ergonomics** | All services expose ports on `localhost`; verbose logging in configs. |
| **Service isolation** | Internal bridges per stack (`pg_internal_dev`, `rc_internal_dev`, …). |
| **Static addressing (where set)** | `ipv4_address` in compose for Postgres replica pair, Mailpit, MinIO (see §6.2). |
| **Single compose per service** | `services/<name>/compose/docker-compose.yml` + `env/dev.env`. |
| **Idempotent networks** | `networks/create-networks.sh` skips existing networks. |
| **Operational symmetry** | Each `services/<name>/` is self-contained (Dockerfile or upstream image, compose, config, Makefile). |

---

## 1.4 Directory structure

```
nestlancer-infrastructure-dev/
├── Makefile                    ← Root interface (dev only)

├── README.md                   ← This document
├── networks/
│   ├── create-networks.sh
│   ├── destroy-networks.sh
│   ├── list-networks.sh
│   └── network-config.yml
├── orchestrator/
│   ├── start-all.sh / stop-all.sh / status.sh / logs.sh
│   ├── restart-service.sh
│   ├── failover-check.sh
│   └── destroy-all.sh
└── services/
    ├── postgres/
    ├── redis-cache/
    ├── redis-pubsub/
    ├── rabbitmq/
    ├── mailpit/
    └── minio/
```

Each service directory typically contains `compose/`, `config/` (where applicable), `env/dev.env`, `scripts/`, `Makefile`, and often `README.md`.

---

## 1.5 Quick start

```bash
cd nestlancer-infrastructure-dev

# 1. Review or customize secrets: services/*/env/dev.env (never reuse dev passwords in prod)

# 2. Create dev networks
make networks-create

# 3. Start the full stack (postgres → redis* → rabbitmq → mailpit → minio)
make env-up

# 4. Verify
make env-status
```

**Examples** after the stack is healthy:

```bash
psql -h localhost -p 5432 -U nl_platform_app -d nl_platform_dev
redis-cli -h localhost -p 6379 -a "$REDIS_PASSWORD"
open http://localhost:15672   # RabbitMQ management
open http://localhost:8025    # Mailpit
open http://localhost:9001    # MinIO console
```

---

# 2. Daily operations

---

## 2.1 Root Makefile — primary interface

| Command | Description |
|:--------|:------------|
| `make help` | List targets with descriptions |
| `make env-up` | Start all dev services (`orchestrator/start-all.sh`) |
| `make env-down` | Stop all dev services |
| `make env-restart` | Stop then start all |
| `make env-status` | Dev status dashboard |
| `make env-logs` | Aggregate logs (`orchestrator/logs.sh all`) |
| `make networks-create` | Create gateway + internal dev networks |
| `make networks-destroy` | Destroy dev networks (impact: connectivity) |
| `make networks-list` | List project networks |
| `make failover-check` | Run `orchestrator/failover-check.sh` |
| `make clean` | Remove containers + volumes **per service** (destructive) |
| `make prune` | `docker system prune` + volume prune |

### Per-service (root delegates to `services/<name>/`)

| Area | Examples |
|:-----|:---------|
| **PostgreSQL** | `postgres-up`, `postgres-down`, `postgres-restart`, `postgres-logs`, `postgres-shell`, `postgres-status`, `postgres-backup`, `postgres-restore FILE=/path/to/backup.sql.gz` |
| **Redis cache** | `redis-cache-up`, `redis-cache-down`, `redis-cache-restart`, `redis-cache-logs`, `redis-cache-shell`, `redis-cache-status` |
| **Redis pub/sub** | `redis-pubsub-up`, … `redis-pubsub-shell`, … |
| **RabbitMQ** | `rabbitmq-up`, … `rabbitmq-backup`, `rabbitmq-restore FILE=/path/to/backup.json` |
| **Mailpit** | `mailpit-up`, `mailpit-down`, `mailpit-restart`, `mailpit-logs`, `mailpit-status` |
| **MinIO** | `minio-up`, `minio-down`, `minio-restart`, `minio-logs`, `minio-status`, `minio-shell` |

---

## 2.2 Service-level commands

From a service directory, targets use **`ENV := dev`** (or an equivalent convention) in each Makefile:

```bash
cd services/postgres
make help
make up      # start primary + replica
make logs
make shell   # psql
```

Same pattern for `redis-cache`, `redis-pubsub`, `rabbitmq`, `mailpit`, `minio`.

---

## 2.3 Orchestrator scripts

Located in `orchestrator/`.

| Script | Purpose |
|:-------|:--------|
| `start-all.sh` | Creates networks, starts services in dependency order |
| `stop-all.sh` | Stops all dev containers |
| `status.sh` | Dashboard (state, health, ports, uptime) |
| `logs.sh` | Default `summary`; `./logs.sh all` tails all; `./logs.sh postgres` per service |
| `restart-service.sh` | `./restart-service.sh postgres` (or `redis-cache`, `rabbitmq`, …) |
| `failover-check.sh` | Stop/start isolation exercise (`make failover-check`) |
| `destroy-all.sh` | Full teardown (use with care) |

---

## 2.4 Network management

```bash
make networks-create
make networks-list
./networks/destroy-networks.sh    # or: make networks-destroy
```

Creates are safe to repeat; existing networks are skipped.

---

## 2.5 Failover check

```bash
make failover-check
# or: ./orchestrator/failover-check.sh
```

---

# 3. Backup & restore

| Service | Method | Notes |
|:--------|:-------|:------|
| **PostgreSQL** | `pg_dump` → compressed dump via service Makefile | `make postgres-backup` / `make postgres-restore FILE=…` |
| **RabbitMQ** | Definitions export → `.json` | `make rabbitmq-backup` / `make rabbitmq-restore FILE=…` |

**Examples:**

```bash
make postgres-backup
make postgres-restore FILE=/path/to/backup.sql.gz

make rabbitmq-backup
make rabbitmq-restore FILE=/path/to/definitions.json
```

There is **no** bundled `backup-all.sh` or `rclone` workflow in this repo; keep dumps on your machine or wire your own automation.

---

# 4. Monitoring & observability

| Task | Command |
|:-----|:--------|
| **Dashboard** | `make env-status` |
| **Logs** | `make env-logs` / `make postgres-logs` / `./orchestrator/logs.sh rabbitmq` |
| **Resource report** | `./scripts/monitor-containers.sh --duration 60 --out-dir /tmp/infra-reports` |
| **Health JSON** | `docker inspect --format='{{json .State.Health}}' postgres-dev \| jq` |
| **Run healthcheck** | `docker exec postgres-dev /usr/local/bin/healthcheck.sh` |

RabbitMQ exposes Prometheus metrics on **localhost:15692**.

---

# 5. Localhost access & data paths

All service ports are bound for **local development** — prefer `127.0.0.1` / `localhost` in connection strings and UIs.

Persistent data (default layout):

```
/root/Desktop/docker-infra-data/dev/{postgres,redis-cache,redis-pubsub,rabbitmq,minio}/…
```

Adjust host paths in each service’s `docker-compose.yml` if your data root differs.

---

# 6. Reference (dev only)

## 6.1 Container names

| Role | Container |
|:-----|:----------|
| PostgreSQL primary | `postgres-dev` |
| PostgreSQL replica | `postgres-replica-dev` |
| Redis cache | `redis-cache-dev` |
| Redis pub/sub | `redis-pubsub-dev` |
| RabbitMQ | `rabbitmq-dev` |
| Mailpit | `mailpit-dev` |
| MinIO | `minio-dev` |

## 6.2 Static IPs (compose)

| Container | Internal network | IPv4 |
|:----------|:-----------------|:-----|
| `postgres-dev` | `pg_internal_dev` | `172.20.1.2` |
| `postgres-replica-dev` | `pg_internal_dev` | `172.20.1.3` |
| `mailpit-dev` | `mailpit_internal_dev` | `172.20.7.2` |
| `minio-dev` | `minio_internal_dev` | `172.20.8.2` |

Other services use internal networks without fixed `ipv4_address` in compose; connect by **service name** on `gateway_dev_network` or via **published host ports**.

## 6.3 Dev networks

| Network | Subnet |
|:--------|:-------|
| `gateway_dev_network` | `172.20.0.0/24` |
| `pg_internal_dev` | `172.20.1.0/28` |
| `rc_internal_dev` | `172.20.2.0/28` |
| `rp_internal_dev` | `172.20.3.0/28` |
| `rmq_internal_dev` | `172.20.4.0/28` |
| `mailpit_internal_dev` | `172.20.7.0/28` |
| `minio_internal_dev` | `172.20.8.0/28` |

## 6.4 Host ports (localhost)

| Service | Host → container |
|:--------|:-----------------|
| PostgreSQL primary | `5432 → 5432` |
| PostgreSQL replica | `5433 → 5432` |
| Redis cache | `6379 → 6379` |
| Redis pub/sub | `6380 → 6379` |
| RabbitMQ AMQP | `5672 → 5672` |
| RabbitMQ management | `15672 → 15672` |
| RabbitMQ Prometheus | `15692 → 15692` |
| Mailpit SMTP | `1025 → 1025` |
| Mailpit Web UI | `8025 → 8025` |
| MinIO API | `9000 → 9000` |
| MinIO Console | `9001 → 9001` |

## 6.5 Compose project names (debugging)

| Service | Compose `-p` |
|:--------|:-------------|
| PostgreSQL | `pg-dev` |
| Redis cache | `rc-dev` |
| Redis pub/sub | `rp-dev` |
| RabbitMQ | `rmq-dev` |
| Mailpit | `mailpit-dev` |
| MinIO | `minio-dev` |

## 6.6 Raw `docker compose` (PostgreSQL example)

```bash
cd services/postgres
docker compose \
  -f compose/docker-compose.yml \
  --env-file env/dev.env \
  -p pg-dev \
  up -d --build

docker compose -p pg-dev ps
docker compose -p pg-dev config
```

Mirror the same pattern for other services (`rc-dev`, `rmq-dev`, …).

## 6.7 Useful Docker commands (dev)

```bash
docker ps --filter "name=dev"
docker stats postgres-dev redis-cache-dev rabbitmq-dev --no-stream
docker logs -f --tail=100 postgres-dev
docker exec -it postgres-dev psql -U nl_infra_admin -d nl_platform_dev
```

---

# 7. Troubleshooting

| Symptom | Likely cause | What to try |
|:--------|:-------------|:------------|
| `env-up` / `up` fails on network | Missing bridge or stale state | `make networks-list`; recreate only if safe |
| **Port already in use** | Another local process | `ss -tulpn \| grep <port>`; stop conflicting service or edit compose ports |
| Health stays **starting** | Long init or wrong secrets | `docker logs <container>`; verify `env/dev.env` |
| PostgreSQL auth errors | Password / `pg_hba` mismatch | Compare `env/dev.env` with `config/dev/pg_hba.conf` |
| Redis `NOAUTH` | Password not passed | Use `-a` / match `redis.conf` `requirepass` |
| MinIO key errors | First-run vs existing data | Check container logs for generated keys and bucket bootstrap |
| Compose changes ignored | Data dir already initialized | Postgres may need volume recreate (know data loss risk) |

---

# 8. Security notes (development)

### Expectations

- [ ] Treat `services/*/env/dev.env` as **non-production** secrets; rotate if you copy this stack elsewhere.
- [ ] **Do not** expose published dev ports to untrusted networks (firewall / bind to localhost only if you harden further).
- [ ] `chmod 600` on env files you keep long-term.
- [ ] After `make clean`, confirm you intended to wipe local volumes.

### Ongoing

- [ ] Use `make env-status` when debugging; review logs after failures.
- [ ] Prefer connecting via `localhost`, not `0.0.0.0`, in application configs when possible.

---

## Further reading

| Document | Contents |
|:---------|:---------|

| **`services/*/README.md`** | Service-specific notes where present |

---

<div align="center">

**Development Docker stack for Nestlancer**

<sub>Structure aligned with <code>nestlancer-infrastructure-prod/README.md</code>; header style inspired by <a href="https://github.com/nestlancer/nestlancer-armory/blob/5368e09b73fc59d59bb6f5c03aa429bf15406077/monitoring/nest-sentinel/readme.md">Nest Sentinel</a>.</sub>

</div>
