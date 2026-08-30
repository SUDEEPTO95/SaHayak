"""Nearest compatible donors. Haversine until PostGIS in backend."""
from __future__ import annotations

import math
from typing import Any

from app.config_loader import load_config
from app.domain.compatibility import is_compatible


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def rank_donors(
    *,
    recipient_group: str,
    origin_lat: float,
    origin_lng: float,
    donors: list[dict[str, Any]],
    radius_km: float,
    now_iso_days_since_donation: dict[str, float] | None = None,
) -> list[dict[str, Any]]:
    cfg = load_config()
    cooling = float(cfg["cooling"]["days_after_whole_blood"])
    ranked: list[dict[str, Any]] = []
    for d in donors:
        if d.get("self_hold"):
            continue
        if not d.get("available", True):
            continue
        if not is_compatible(recipient_group, d["blood_group"]):
            continue
        last = (now_iso_days_since_donation or {}).get(d["id"], 999)
        if last < cooling:
            continue
        dist = haversine_km(origin_lat, origin_lng, float(d["lat"]), float(d["lng"]))
        if dist > radius_km:
            continue
        item = dict(d)
        item["distance_km"] = round(dist, 2)
        item.pop("phone", None)
        ranked.append(item)
    ranked.sort(key=lambda x: x["distance_km"])
    return ranked
