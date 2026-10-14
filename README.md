# All-in-one local development resources

One `docker compose up` gives you the infrastructure most apps need during local development:

| Service | What for | Address |
| --- | --- | --- |
| **PostgreSQL 18** | Relational database | `localhost:5432` |
| **Redis 8** | Cache, queues, sessions | `localhost:6379` |
| **[Garage](https://garagehq.deuxfleurs.fr/)** | S3-compatible object storage | `localhost:3900` |

Every service has working default credentials, a healthcheck and a persistent volume. No setup step is needed: the S3 bucket and access key are created automatically.

## Quick start

Requires Docker with Docker Compose v2 (Docker Desktop, OrbStack, Colima or Docker Engine).

```sh
git clone https://github.com/nunoxavier/aio-local-resources.git
cd aio-local-resources
docker compose up -d --wait
```

The `--wait` flag returns once all services are healthy. Stop them with `docker compose down`. Your data is kept until you run `docker compose down -v`.

## Connection details

Copy whatever your app needs into its own `.env`:

```sh
# PostgreSQL
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/postgres

# Redis
REDIS_URL=redis://localhost:6379

# S3 (Garage)
AWS_ENDPOINT_URL=http://localhost:3900
AWS_REGION=garage
AWS_ACCESS_KEY_ID=GK000000000000000000000000
AWS_SECRET_ACCESS_KEY=0000000000000000000000000000000000000000000000000000000000000000
S3_BUCKET=local
```

S3 notes:

- Use **path-style** addressing (`http://localhost:3900/local/key`). Most SDKs call this `forcePathStyle: true` (JavaScript), `use_path_style_endpoint` (PHP/Laravel) or `addressing_style: "path"` (boto3).
- The region must be `garage`.

For example, with the AWS CLI:

```sh
aws --endpoint-url http://localhost:3900 s3 cp ./photo.jpg s3://local/photo.jpg
aws --endpoint-url http://localhost:3900 s3 ls s3://local
```

## Configuration

Defaults are built into `docker-compose.yml`. To change ports or credentials, copy the example file and uncomment what you need:

```sh
cp .env.example .env
```

The variables are listed in [`.env.example`](.env.example). Some only take effect on first start:

- **Postgres:** user, password and database name are applied only when the volume is empty. Run `docker compose down -v` to recreate it.
- **S3:** changing the access key or bucket later creates a new key and bucket alongside the existing ones.

Ports are published on `127.0.0.1` only, so the services can't be reached from your network. Set `BIND_ADDRESS=0.0.0.0` if you need to reach them from another machine.

> These defaults are for local development only. Don't use this setup in production.

## Make shortcuts

If you have `make`, these wrap the Compose commands:

| Command | Does |
| --- | --- |
| `make up` | Start everything and wait until healthy |
| `make down` | Stop everything (data is kept) |
| `make restart` | Restart everything |
| `make ps` | Show status |
| `make logs` | Follow logs (`make logs s=garage` for one service) |
| `make psql` | Open a `psql` shell |
| `make redis-cli` | Open a `redis-cli` shell |
| `make reset` | Stop everything and **delete all data** |

## Using from other Compose projects

The services run on a Docker network named `aio-local-resources`. To use them from another Compose project's containers, join that network:

```yaml
# your-app/docker-compose.yml
services:
  app:
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/postgres
      REDIS_URL: redis://redis:6379
      AWS_ENDPOINT_URL: http://garage:3900

networks:
  default:
    name: aio-local-resources
    external: true
```

Inside the network, the hostnames are `postgres`, `redis` and `garage`, always on the default ports, whatever `.env` sets.

## Managing S3 buckets and keys

Use the Garage CLI inside the container:

```sh
docker compose exec garage /garage bucket list
docker compose exec garage /garage bucket create my-bucket
docker compose exec garage /garage bucket allow --read --write --owner my-bucket --key GK000000000000000000000000
docker compose exec garage /garage key create my-app
```

### Static website hosting

Garage can serve a bucket as a website on port `3902`:

```sh
docker compose exec garage /garage bucket website --allow local
```

The bucket is then served at <http://local.web.garage.localhost:3902>, with `index.html` as the index page.

## Upgrading

Image versions are pinned in `docker-compose.yml`. Minor updates (`docker compose pull && docker compose up -d`) are safe. A new **major** Postgres version can't read the old data directory: run `pg_dump` first, reset the volume, then restore.

## License

[MIT](LICENSE)
