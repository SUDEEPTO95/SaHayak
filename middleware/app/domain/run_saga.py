"""
Execute the locked saga against the store. Each method is one chunk.
Notices go through NotifyPort (FCM/WhatsApp off = in-memory log).
"""
from __future__ import annotations

import time
from typing import Any

from app.domain.matching import rank_donors
from app.domain.orchestrate_blood_request import escalate_wait_minutes
from app.notify import notify
from app.store import STORE
from app.config_loader import load_config


class RunBloodRequestSaga:
    """Full orchestration. Same order as the product plan."""

    def __init__(self) -> None:
        self.cfg = load_config()

    def run(self, rec: dict[str, Any]) -> dict[str, Any]:
        log: list[str] = []
        log.append(self._merge_already_done())
        log.append(self._family_ring(rec))
        log.append(self._society_ring(rec))
        ranked, radius = self._match(rec)
        rec["matched_donor_ids"] = [d["id"] for d in ranked]
        rec["match_radius_km"] = radius
        log.append("match_nearest_compatible")
        tid = rec.get("tenant_id", "public")
        hush = STORE.festival_hush.get(tid) or STORE.festival_hush.get("public")
        if rec.get("lane") == "regular":
            rec["public_pinged"] = []
            rec["quiet"] = True
            log.append("quiet_lane_no_public")
        elif hush:
            rec["public_pinged"] = []
            rec["festival_hush"] = True
            log.append("festival_hush_hold_public")
        elif rec.get("women_first"):
            women = [d for d in ranked if d.get("woman")]
            others = [d for d in ranked if not d.get("woman")]
            if women:
                rec["women_first_held_ids"] = [d["id"] for d in others]
                rec["women_first_active"] = True
                log.append(self._public_ping(rec, women))
                rec.setdefault("saga_extra", [])
                log.append("women_first_ping")
            else:
                rec["women_first_held_ids"] = []
                log.append(self._public_ping(rec, ranked))
        else:
            log.append(self._public_ping(rec, ranked))
        wait_m = escalate_wait_minutes(rec.get("urgency", "critical"), self.cfg)
        if rec.get("lane") == "regular":
            wait_m = max(wait_m, 120)
        if hush:
            wait_m = max(wait_m, 1) * 4
        if STORE.disaster_mode.get(tid) or STORE.disaster_mode.get("public"):
            wait_m = 0
        rec["escalate_wait_minutes"] = wait_m
        rec["pending_escalate_at"] = time.time() + wait_m * 60
        rec["last_unit"] = False
        log.append("wait_or_last_unit")
        rec["saga"] = log
        STORE.requests[rec["id"]] = rec
        STORE.save()
        return rec

    def maybe_escalate(self, rec: dict[str, Any]) -> dict[str, Any]:
        if rec.get("lane") == "regular":
            return rec
        if rec.get("status") != "open" or rec.get("last_unit"):
            return rec
        due = float(rec.get("pending_escalate_at") or 0)
        if rec.get("units_accepted", 0) > 0:
            return rec
        if time.time() < due:
            return rec
        if rec.get("women_first_active") and not rec.get("women_first_widened"):
            held = [STORE.donors[i] for i in (rec.get("women_first_held_ids") or []) if i in STORE.donors]
            if held:
                self._public_ping(rec, held)
            rec["women_first_widened"] = True
            rec["pending_escalate_at"] = time.time() + 15 * 60
            rec.setdefault("saga", []).append("women_first_widen")
            STORE.requests[rec["id"]] = rec
            STORE.save()
            return rec
        rec["last_unit"] = True
        banks = [e for e in STORE.directory if e.get("kind") in ("hospital", "blood_bank", "ngo")]
        rec["escalated_orgs"] = [e.get("name") for e in banks[:10]]
        for e in banks[:10]:
            notify("last_unit", e.get("id", e.get("name")), rec["id"], "Last-unit: no accept yet. Hospitals and banks are told.")
        rec.setdefault("saga", []).append("last_unit_escalation")
        STORE.requests[rec["id"]] = rec
        STORE.save()
        return rec

    def _merge_already_done(self) -> str:
        return "merge_twins"

    def _family_ring(self, rec: dict[str, Any]) -> str:
        members = STORE.family_rings.get(rec["seeker_id"], [])
        for m in members:
            notify("family_ring", m, rec["id"], "A trusted person needs compatible blood nearby.")
        rec["family_ring_notified"] = list(members)
        return "notify_family_ring"

    def _society_ring(self, rec: dict[str, Any]) -> str:
        if rec.get("lane") == "regular":
            rec["society_ring_notified"] = []
            return "notify_society_ring"
        sid = rec.get("society_id") or STORE.users.get(rec["seeker_id"], {}).get("society_id")
        members = STORE.society_rings.get(sid, []) if sid else []
        for m in members:
            if m != rec["seeker_id"]:
                notify("society_ring", m, rec["id"], "Someone in your society needs blood.")
        rec["society_ring_notified"] = list(members)
        return "notify_society_ring"

    def _match(self, rec: dict[str, Any]) -> tuple[list[dict[str, Any]], float]:
        steps = [float(x) for x in self.cfg["matching"]["radius_km_steps"]]
        if STORE.disaster_mode.get(rec.get("tenant_id", "public")):
            steps = [max(steps), 80.0]
        donors = list(STORE.donors.values())
        last_km: dict[str, float] = {}
        now = time.time()
        for d in donors:
            if d.get("last_donation_at"):
                last_km[d["id"]] = (now - float(d["last_donation_at"])) / 86400.0
            else:
                last_km[d["id"]] = 999
        ranked: list[dict[str, Any]] = []
        used = steps[0]
        for radius in steps:
            ranked = rank_donors(
                recipient_group=rec["recipient_group"],
                origin_lat=float(rec["lat"]),
                origin_lng=float(rec["lng"]),
                donors=donors,
                radius_km=radius,
                now_iso_days_since_donation=last_km,
            )
            used = radius
            if ranked:
                break
        return ranked, used

    def _public_ping(self, rec: dict[str, Any], ranked: list[dict[str, Any]]) -> str:
        hours = float(self.cfg["matching"]["ping_rest_hours"])
        now = time.time()
        sent = []
        for d in ranked:
            last = STORE.ping_last.get(d["id"], 0)
            if now - last < hours * 3600:
                continue
            notify("public", d["id"], rec["id"], "Compatible request nearby.")
            STORE.ping_last[d["id"]] = now
            sent.append(d["id"])
        rec["public_pinged"] = list(rec.get("public_pinged") or []) + sent
        return "notify_public_ping_rest"
