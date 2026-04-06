# Redis Pub/Sub Service Unit

Self-contained Redis instance tuned for pub/sub; message data is ephemeral.

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
