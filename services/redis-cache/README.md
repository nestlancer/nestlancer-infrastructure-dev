<div align="center">

# Redis Cache Service Unit — Development

### High-performance cache · local development · 172.20.2.x network

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Linux](https://img.shields.io/badge/Host-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://kernel.org/)

<br/>

**Local-dev ready:** Self-contained Redis cache service with RDB+AOF persistence for local development.

<br/>

[Quick Start](#quick-start) •
[Targets](#makefile-targets) •
[Config](#configuration) •
[Troubleshooting](#troubleshooting)

<br/>

---

</div>

<br/>

## Table of contents

<details>
<summary><b>Expand full outline</b></summary>

- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Makefile Targets](#makefile-targets)
- [Configuration](#configuration)
- [Port Mapping (dev)](#port-mapping-dev)
- [Troubleshooting](#troubleshooting)
- [Readiness](#readiness)

</details>

---

## Quick Start

```bash
make up       # Start Redis Cache (from this service directory)
make shell    # Open redis-cli
make logs     # Tail logs
```

From the repository root, use `make redis-cache-up`, `make redis-cache-shell`, etc.

## Prerequisites

- Docker Engine 24+
- Docker Compose V2+
- `make` utility

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make up` | Start Redis Cache |
| `make down` | Stop Redis Cache |
| `make restart` | Restart |
| `make logs` | Tail container logs |
| `make shell` | Open redis-cli |
| `make status` | Container status + health |
| `make build` / `make rebuild` | Build image |
| `make clean` | Remove container and volumes |

## Configuration

- `config/base/redis.conf` — shared baseline
- `config/dev/redis.conf` — dev overrides
- `env/dev.env` — passwords and tunables

## Port Mapping (dev)

| Host | Container |
|------|-----------|
| `6379` | `6379` |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `NOAUTH` error | Match `REDIS_PASSWORD` in `env/dev.env` with config |
| Port conflict | Check `docker ps` for another process on 6379 |

## Readiness

`scripts/wait-for-self.sh` can be used from the host or other tooling to wait until Redis responds to `PING`.
