"""Small helpers for the calm extras. Keep matching/saga logic elsewhere."""
from __future__ import annotations

import re
import time
from typing import Any

from app.config_loader import load_config


def hospital_key(name: str | None) -> str:
    s = (name or "").lower()
    for w in ("hospital", "centre", "center", "blood bank", "medical college", ","):
        s = s.replace(w, " ")
    return " ".join(s.split())


def is_night_open(entry: dict[str, Any]) -> bool:
    if entry.get("night_open"):
        return True
    hours = (entry.get("hours") or "").replace(" ", "")
    if not hours:
        return False
    if "00:00-24:00" in hours or hours in ("24h", "24hr", "24hrs"):
        return True
    # Window that includes late night, including wrap (22:00-06:00).
    m = re.match(r"(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})", hours)
    if not m:
        return "22:" in hours or "23:" in hours
    a = int(m.group(1)) * 60 + int(m.group(2))
    b = int(m.group(3)) * 60 + int(m.group(4))
    night = 22 * 60
    if b <= a:
        return True
    return a <= night < b or a < 6 * 60


NIGHT_PLACES = [
    {
        "id": "dir-nrs-night",
        "kind": "blood_bank",
        "name": "NRS Blood Centre (night desk)",
        "state": "West Bengal",
        "district": "Kolkata",
        "phone": "033-22653214",
        "hours": "22:00-06:00",
        "lat": 22.562,
        "lng": 88.370,
        "open_now": True,
        "night_open": True,
    },
    {
        "id": "dir-tata-night",
        "kind": "blood_bank",
        "name": "Tata Medical night desk",
        "state": "West Bengal",
        "district": "Kolkata",
        "phone": "033-66057000",
        "hours": "22:00-08:00",
        "lat": 22.580,
        "lng": 88.410,
        "open_now": True,
        "night_open": True,
    },
]


def ensure_night_places(directory: list[dict[str, Any]]) -> bool:
    ids = {e.get("id") for e in directory}
    added = False
    for row in NIGHT_PLACES:
        if row["id"] not in ids:
            directory.append(dict(row))
            added = True
    return added


def clean_notebook_person(who: str, group: str) -> dict[str, str] | None:
    label = " ".join((who or "").split())[:24]
    g = (group or "").upper().replace(" ", "")
    if not label or g not in load_config()["blood_groups"]:
        return None
    return {"who": label, "group": g}


def ride_expires(minutes: int) -> float:
    m = max(10, min(180, int(minutes or 40)))
    return time.time() + m * 60


def window_alive(row: dict[str, Any], now: float | None = None) -> bool:
    now = now if now is not None else time.time()
    exp = row.get("expires_at")
    if exp is None:
        return True
    return float(exp) > now


def same_night_mates(requests: dict[str, dict[str, Any]], rec: dict[str, Any]) -> list[dict[str, Any]]:
    key = hospital_key(rec.get("hospital_name"))
    if not key:
        return []
    out = []
    for r in requests.values():
        if r.get("id") == rec.get("id"):
            continue
        if r.get("status") != "open":
            continue
        if hospital_key(r.get("hospital_name")) != key:
            continue
        out.append(
            {
                "group": r.get("recipient_group"),
                "units_progress": f"{r.get('units_accepted', 0)}/{r.get('units_needed', 0)}",
                "ward": r.get("ward") or "",
            }
        )
    return out
