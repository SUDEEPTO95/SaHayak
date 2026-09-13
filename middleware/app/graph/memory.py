"""Bounded topic and semantic memory for the AI crew."""
from __future__ import annotations

from typing import Any

from app.store import STORE


def read_memory(user_id: str, tenant_id: str) -> list[dict[str, Any]]:
    rows = STORE.ai_memory.get(f"{tenant_id}:{user_id}", [])
    return [dict(row) for row in rows[-10:]]


def remember(user_id: str, tenant_id: str, row: dict[str, Any]) -> None:
    key = f"{tenant_id}:{user_id}"
    rows = STORE.ai_memory.setdefault(key, [])
    rows.append({
        "intent": row.get("intent"),
        "language": row.get("language", "en"),
        "topic": row.get("topic") or row.get("parsed", {}).get("recipient_group"),
        "outcome": row.get("outcome") or ("refused" if row.get("intent") == "refuse" else "completed"),
    })
    STORE.ai_memory[key] = rows[-20:]
    STORE.save()