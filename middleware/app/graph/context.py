"""Resolve bounded, tenant-aware context before an AI graph run."""
from __future__ import annotations

from typing import Any


def resolve_context(*, text: str, user: dict[str, Any], lat: float, lng: float, memory: list[dict[str, Any]]) -> dict[str, Any]:
    """Return only context the graph needs; never include tokens or phone numbers."""
    safe_user = {
        key: value
        for key, value in user.items()
        if key not in {"token", "phone", "seeker_phone"}
    }
    return {
        "text": (text or "")[:2000],
        "user": safe_user,
        "tenant_id": safe_user.get("tenant_id", "public"),
        "role": safe_user.get("role", "user"),
        "language": safe_user.get("language", "en"),
        "location": {"lat": float(lat), "lng": float(lng)},
        "memory": memory[-10:],
    }