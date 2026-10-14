# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A public repo with a Docker Compose setup that gives developers local Postgres, Redis and S3-compatible storage (Garage) with one `docker compose up`. There is no application code, build step, linter or test suite. The main design goal is simplicity: a fresh clone must work with plain `docker compose up -d --wait`, with no `.env`, no `make` and no manual setup step. Keep it that way when making changes.

## How it fits together

- `docker-compose.yml` is the single source of truth. Every setting is `${VAR:-default}`, and `.env.example` documents the same variables with the same defaults, all commented out. When adding or changing a variable, update `docker-compose.yml`, `.env.example` and the README together.
- Garage needs no manual setup: `garage server --single-node --default-bucket` (Garage ≥ v2.3.0) sets up the layout and creates the access key and bucket from the `GARAGE_DEFAULT_*` env vars on every start. This is idempotent. Changing the vars later adds a new key or bucket and leaves the old ones in place. Key IDs must be `GK` + 24 hex chars, and secrets 64 hex chars. `rpc_secret` is deliberately left out of `garage.toml` and comes from `GARAGE_RPC_SECRET`.
- Ports are published on `${BIND_ADDRESS:-127.0.0.1}`, because the default credentials are public.
- The default network has a fixed name, `local-dev-services`, so other Compose projects can join it as `external`. There are no `container_name`s, which avoids clashes. Use `docker compose exec <service>`.
- Postgres 18+ mounts its volume at `/var/lib/postgresql`, not `/var/lib/postgresql/data`.
- The `Makefile` is an optional thin wrapper around `docker compose`. `make` with no target prints help, generated from the `## ` comments.

## Testing changes

Run a throwaway stack on spare ports, so it doesn't clash with a running stack or with services already on the host:

```sh
POSTGRES_PORT=15432 REDIS_PORT=16379 S3_PORT=13900 S3_WEB_PORT=13902 docker compose -p aiotest up -d --wait
docker compose -p aiotest exec garage /garage bucket list
docker compose -p aiotest down -v
```

The network name is fixed, so a test stack and a real stack can't run at the same time. S3 requests can be checked without the AWS CLI using `curl --aws-sigv4 "aws:amz:garage:s3" --user "$KEY:$SECRET"`.
