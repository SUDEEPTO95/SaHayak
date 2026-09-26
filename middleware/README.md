# Middleware (only `/v1` HTTP)

This folder is the **public contract**. Frontend talks here. Backend (Laravel domain, AI) is not imported by Flutter.

Runnable server: FastAPI (`app/main.py`). Laravel twin lives in `../backend/laravel` (same saga names) until PHP is installed.

## PostgreSQL/PostGIS readiness

The app currently uses a transactional SQLAlchemy snapshot store. It defaults to SQLite for zero-configuration development and switches to PostgreSQL when `DATABASE_URL` is set. Use the PostGIS service in `../infra/docker-compose.yml`, set `DATABASE_URL` in `.env`, and apply `schema/001_postgis_core.sql` after reviewing credentials and retention policy.

The schema provides tenants, users, donors, blood requests, directory entries, inventory, audit events, geography indexes, constraints, and a safe public tenant seed. No migration runs automatically and no credentials are stored in Git.
