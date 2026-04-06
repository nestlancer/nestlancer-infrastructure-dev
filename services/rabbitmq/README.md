# RabbitMQ Service Unit

RabbitMQ with Management and Prometheus plugins for local development.

## Quick Start

```bash
make up       # Start RabbitMQ (from this service directory)
make shell    # Open rabbitmq-diagnostics shell
make logs     # Tail logs
```

From the repository root, use `make rabbitmq-up`, `make rabbitmq-shell`, etc.

## Management UI

- [http://localhost:15672](http://localhost:15672) — credentials in `env/dev.env`

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make up` | Start RabbitMQ |
| `make down` | Stop RabbitMQ |
| `make restart` | Restart |
| `make logs` | Tail logs |
| `make shell` | Diagnostics shell |
| `make status` | Status + health |
| `make backup` | Export definitions to container backup dir |
| `make restore FILE=<path>` | Import definitions |
| `make build` / `make rebuild` | Build image |
| `make clean` | Remove container and volumes |

## Ports (dev)

| Service | Host |
|---------|------|
| AMQP | `5672` |
| Management UI | `15672` |
| Prometheus | `15692` |
