# Backend — domain, database, AI. Not called by Flutter.

- `laravel/` — PHP domain (MatchCompatibleDonors, OrchestrateBloodRequest). Same saga as middleware.
- `ai/` — LangGraph crew. Middleware calls this later; frontend never does.

Postgres/PostGIS later is owned here (see `infra/docker-compose.yml` at repo root).
