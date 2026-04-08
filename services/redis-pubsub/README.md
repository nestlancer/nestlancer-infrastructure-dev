<div align="center">

# Redis Pub/Sub Service Unit — Development

### Messaging engine · local development · 172.20.3.x network

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Linux](https://img.shields.io/badge/Host-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://kernel.org/)

<br/>

**Local-dev ready:** Self-contained Redis instance tuned for pub/sub; message data is ephemeral.

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
make up       # Start Redis Pub/Sub (from this service directory)
make shell    # Open redis-cli
make logs     # Tail logs
```

From the repository root, use `make redis-pubsub-up`, `make redis-pubsub-shell`, etc.

## Prerequisites

- Docker Engine 24+
- Docker Compose V2+
- `make` utility

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make up` | Start service |
| `make down` | Stop service |
| `make restart` | Restart |
| `make logs` | Tail logs |
| `make shell` | Open redis-cli |
| `make status` | Status + health |
| `make build` / `make rebuild` | Build image |
| `make clean` | Remove container and volumes |

## Configuration

- `config/base/redis.conf` — shared baseline
- `config/dev/redis.conf` — dev overrides (keyspace notifications, `noeviction`, etc.)
- `env/dev.env` — passwords and tunables

## Port Mapping (dev)

| Host | Container |
|------|-----------|
| `6380` | `6379` |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Messages not received | Check subscribers and keyspace events in config |
| `NOAUTH` | Set `REDIS_PASSWORD` in `env/dev.env` |
| Port conflict | Another container may be using `6380` |

## Readiness

`scripts/wait-for-self.sh` waits until Redis responds to `PING`.
