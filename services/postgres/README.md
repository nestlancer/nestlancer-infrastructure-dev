# PostgreSQL Service Unit

Self-contained PostgreSQL (primary + optional read replica) for local development, with base + dev config merging and init scripts.

## Quick Start

```bash
make up       # Start primary and replica (from this service directory)
make shell    # Interactive psql
make status   # Health and container info
```

From the repository root: `make postgres-up`, `make postgres-shell`, etc.

## Architecture

- **Config**: `config/base/*` plus `config/dev/*` merged at startup into the data directory.
- **Init**: `init/*.sh` run on first database initialization only.
- **Replica**: `postgres-replica` clones the primary via `pg_basebackup` when its data directory is empty.

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make up` | Start stack (`docker compose up -d --build`) |
| `make down` | Stop, keep data |
| `make restart` | Restart containers |
| `make logs` | Follow logs |
| `make shell` | `psql` as superuser from `env/dev.env` |
| `make status` | Primary + replica status |
| `make backup` | Timestamped backup (waits until DB is ready) |
| `make restore FILE=<path>` | Restore from `.sql.gz` |
| `make clean` | **Destructive**: remove containers and volumes |

## Roles (created on first init)

| Role | Variable (see `env/dev.env`) |
|------|------------------------------|
| Superuser | `POSTGRES_USER` |
| Application | `APP_DB_USER` |
| Read-only | `READONLY_DB_USER` |
| Replication | `REPLICATION_USER` |

## Changing variables after first init

Core users/passwords are applied at **first init** only. To change passwords on a running DB, use `ALTER ROLE` in `psql` and then update `env/dev.env`. To re-init from scratch: `make clean` then `make up` (**deletes data**).

## Read replication (dev)

- Primary: host port **5432**
- Replica: host port **5433** (read-only)

## Backup & Restore

Backups live under the host path configured in the Makefile (`DATA_PATH_BASE`) and inside the container under `/var/lib/postgresql/backups`.

```bash
make backup
make restore FILE=./path/to/backup.sql.gz
```

## Layout

```text
compose/docker-compose.yml   # Service definition
config/base/                 # Shared postgresql.conf / pg_hba
config/dev/                  # Dev overrides
env/dev.env                  # Secrets and tunables
init/                        # 00–03 init scripts
scripts/                     # entrypoint, healthcheck, backup, restore
docker/Dockerfile
Makefile
```
