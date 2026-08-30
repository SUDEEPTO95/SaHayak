"""Tools the graph may call. They use domain + store — never invent donors, never SQL."""
from __future__ import annotations

import time
from typing import Any

from app.config_loader import load_config
from app.domain.matching import rank_donors
from app.graph.knowledge import retrieve
from app.store import STORE


def search_donors(*, recipient_group: str, lat: float, lng: float) -> list[dict[str, Any]]:
    cfg = load_config()
    return rank_donors(
        recipient_group=recipient_group,
        origin_lat=lat,
        origin_lng=lng,
        donors=list(STORE.donors.values()),
        radius_km=float(cfg["matching"]["radius_km_steps"][0]),
    )


def family_ring_first(user_id: str) -> list[str]:
    return list(STORE.family_rings.get(user_id, []))


def who_to_notify(user_id: str, matched_ids: list[str]) -> dict[str, list[str]]:
    """Outreach order is locked: Family Ring, then public matches. Cannot skip family."""
    family = family_ring_first(user_id)
    public = [i for i in matched_ids if i not in family]
    return {"family_ring": family, "then_public": public, "skipped_family": False}


def ops_snapshot(role: str) -> dict[str, Any]:
    if role not in ("owner", "tenant_admin"):
        return {"allowed": False}
    now = time.time()
    stale = [
        r["id"]
        for r in STORE.requests.values()
        if r.get("status") == "open" and now - float(r.get("created_at") or now) > 6 * 3600
    ]
    return {
        "allowed": True,
        "open_requests": sum(1 for r in STORE.requests.values() if r.get("status") == "open"),
        "stale_open_ids": stale[:20],
        "donors": len(STORE.donors),
        "camps": len(STORE.camps),
        "directory": len(STORE.directory),
        "note": "Light stock is not live inventory. Officers still confirm with the bank.",
    }


def knowledge_search(query: str) -> list[str]:
    return retrieve(query)


def strip_phones(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out = []
    for r in rows:
        item = dict(r)
        item.pop("phone", None)
        out.append(item)
    return out
