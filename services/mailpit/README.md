<div align="center">

# Mailpit Service Unit — Development

### SMTP Testing · Web UI with Authentication · Persistent Storage

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Mailpit](https://img.shields.io/badge/Service-Mailpit-ED4337?style=for-the-badge&logo=mail.ru&logoColor=white)](https://github.com/axllent/mailpit)

<br/>

**Local-dev ready:** Self-contained Mailpit instance for capturing and inspecting emails during development. Features version pinning, persistence, and basic authentication for the Web UI.

<br/>

[Quick Start](#quick-start) •
[Features](#features) •
[Makefile Targets](#makefile-targets) •
[Authentication](#authentication) •
[Persistence](#persistence)

<br/>

---

</div>

<br/>

## Table of contents

<details>
<summary><b>Expand full outline</b></summary>

- [Quick Start](#quick-start)
- [Features](#features)
- [Makefile Targets](#makefile-targets)
- [Authentication](#authentication)
- [Persistence](#persistence)
- [Layout](#layout)

</details>

---

## Quick Start

```bash
make up       # Start Mailpit (from this service directory)
make status   # Check container status
make logs     # Follow logs
```

From the repository root: `make mailpit-up`, `make mailpit-status`, etc.

## Features

- **Version Pinning**: Uses `v1.29.6` for predictable environments.
- **Persistence**: Emails are stored in a SQLite database on the host.
- **Security**: Basic authentication required for the Web UI.
- **Healthchecks**: Built-in SMTP health monitoring.
- **Resource Limits**: Configured with a 256MB memory limit.

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make up` | Start Mailpit (`docker compose up -d --build`) |
| `make down` | Stop, keep data |
| `make restart` | Restart container |
| `make logs` | Follow logs |
| `make status` | Container status |
| `make clean` | **Destructive**: remove container and volume |

## Authentication

The Web UI is protected by Basic Authentication. Credentials are managed in `env/dev.env` via separate variables:

- **Username**: `MAILPIT_UI_USER` (Default: `admin`)
- **Password**: `MAILPIT_UI_PASS` (Default: `nestlancer-mail-secure`)

## Persistence

Backups and captured emails live under the host path configured in the Makefile (`DATA_PATH_BASE`). Inside the container, this is mapped to `/data`.

- **Database File**: `/data/mailpit.db`
- **Max Messages**: 5000 (Configurable via `MP_MAX_MESSAGES`)

## Layout

```text
compose/docker-compose.yml   # Service definition
env/dev.env                  # Credentials and message limits
Makefile                     # Service-level automation
README.md                    # This document
```
