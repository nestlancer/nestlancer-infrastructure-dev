<div align="center">

# RabbitMQ Service Unit — Development

### Message broker · local development · 172.20.4.x network

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Linux](https://img.shields.io/badge/Host-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://kernel.org/)

<br/>

**Local-dev ready:** RabbitMQ with Management and Prometheus plugins for local development.

<br/>

[Quick Start](#quick-start) •
[Management UI](#management-ui) •
[Targets](#makefile-targets) •
[Ports](#ports-dev)

<br/>

---

</div>

<br/>

## Table of contents

<details>
<summary><b>Expand full outline</b></summary>

- [Quick Start](#quick-start)
- [Management UI](#management-ui)
- [Makefile Targets](#makefile-targets)
- [Ports (dev)](#ports-dev)

</details>

---

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
