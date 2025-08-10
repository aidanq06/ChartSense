# ChartSense Backend v2

This is a clean-slate backend for ChartSense. It consists of:

- Postgres schema (SQL migrations in `sql/`)
- API service (Fastify, TypeScript) in `api/`
- Worker service (TypeScript) in `worker/` for scheduled ingest/caching
- Local dev stack via Docker Compose (Postgres + Redis)

## Quick start (local)

1) Start infra

```bash
cd backend
docker compose up -d
```

2) Apply initial schema

```bash
psql postgres://chartsense:chartsense@localhost:5432/chartsense -f sql/0001_init.sql
```

3) Configure envs

```bash
cp env.example .env
# Fill FINNHUB_TOKEN, JWT_SECRET, etc.
```

4) Run API and Worker (in separate terminals)

```bash
cd backend/api && npm i && npm run dev
cd backend/worker && npm i && npm run dev
```

The worker will refresh quotes every 5 minutes and upsert into Postgres.

## Deploy

- Database: Neon/Render/PlanetScale Postgres (recommended: Neon)
- Cache: Upstash Redis (optional initially)
- API: Fly.io/Render/Railway (single container)
- Worker: Fly.io/Render/Railway with a platform cron or always-on process

## iOS Integration

- Use `X-User-Id` header during development.
- Preferred: use JWT from `/v1/auth/register` or `/v1/auth/login` and set `Authorization: Bearer <token>`
- Replace current direct-Finnhub calls with API endpoints:
  - GET `/v1/market/quote?symbol=SYMBOL`
  - GET `/v1/market/candles?symbol=SYMBOL&timeframe=5m|1d&from=...&to=...`
  - Watchlists: GET/POST `/v1/watchlists`, item add/remove
  - Alerts: POST `/v1/alerts`
  - AI chat: POST `/v1/ai/chat` (enforces daily limits)

## Requirements

- Node.js 20+
- Docker (for local Postgres/Redis)


