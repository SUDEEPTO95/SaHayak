"""Real transactional database layer backing SaHayak's application state.

Uses SQLAlchemy so the exact same code works with SQLite (zero-config
default, used for dev/tests) or PostgreSQL (already provisioned in
infra/docker-compose.yml) by only changing the DATABASE_URL environment
variable — no application code changes needed either way.

Every save() writes the whole in-memory snapshot back inside one ACID
transaction: either every collection lands, or none do. That replaces the
old plain "write a JSON file" approach, which could leave a half-written
or corrupted file if the process died mid-write or two requests wrote at
the same time.
"""
from __future__ import annotations

import os
import threading
from pathlib import Path

from sqlalchemy import Column, MetaData, String, Table, Text, create_engine, select

_DATA_DIR = Path(__file__).resolve().parent.parent / "data"


def _default_url() -> str:
    _DATA_DIR.mkdir(parents=True, exist_ok=True)
    return f"sqlite:///{(_DATA_DIR / 'sahayak.db').as_posix()}"


DATABASE_URL = os.getenv("DATABASE_URL", _default_url())

_engine_kwargs: dict = {"future": True}
if DATABASE_URL.startswith("sqlite"):
    # Allow use from FastAPI's thread pool; WAL below makes that safe.
    _engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_engine(DATABASE_URL, **_engine_kwargs)

if DATABASE_URL.startswith("sqlite"):
    with engine.connect() as conn:
        conn.exec_driver_sql("PRAGMA journal_mode=WAL")
        conn.exec_driver_sql("PRAGMA synchronous=NORMAL")

metadata = MetaData()

# One row per top-level collection (users, donors, requests, ...). Each row
# holds that collection's full JSON snapshot. save_all() replaces every row
# inside a single transaction, so a crash mid-save can never leave a mix of
# old and new collections.
store_state = Table(
    "store_state",
    metadata,
    Column("collection", String(64), primary_key=True),
    Column("data", Text, nullable=False),
)

metadata.create_all(engine)

# Serializes save_all() across threads: FastAPI runs sync endpoints in a
# thread pool, so two requests could otherwise interleave writes.
_save_lock = threading.Lock()


def load_all() -> dict[str, str]:
    """Return {collection_name: json_text} for every stored collection."""
    with engine.connect() as conn:
        rows = conn.execute(select(store_state.c.collection, store_state.c.data)).all()
    return {row.collection: row.data for row in rows}


def save_all(snapshot: dict[str, str]) -> None:
    """Atomically replace the whole state with the given collections."""
    with _save_lock, engine.begin() as conn:
        conn.execute(store_state.delete())
        if snapshot:
            conn.execute(
                store_state.insert(),
                [{"collection": k, "data": v} for k, v in snapshot.items()],
            )
