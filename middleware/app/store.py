"""Durable in-process store. Backed by a real transactional database (see app/db.py);
SQLite by default, PostgreSQL when DATABASE_URL points at the docker-compose instance."""
from __future__ import annotations

import json
import secrets
import time
import uuid
from pathlib import Path
from typing import Any

from app.config_loader import load_config
from app.db import load_all, save_all

# Legacy JSON file from before the database migration. Only read once, to
# carry forward any existing data the first time this runs against a fresh
# database. Never written to again after that.
_LEGACY_DATA = Path(__file__).resolve().parent.parent / "data" / "store.json"


class MemoryStore:
    def __init__(self) -> None:
        self.users: dict[str, dict[str, Any]] = {}
        self.otps: dict[str, tuple[str, float]] = {}
        self.otp_hits: dict[str, list[float]] = {}
        self.tokens: dict[str, str] = {}
        self.donors: dict[str, dict[str, Any]] = {}
        self.requests: dict[str, dict[str, Any]] = {}
        self.directory: list[dict[str, Any]] = []
        self.family_rings: dict[str, list[str]] = {}
        self.society_rings: dict[str, list[str]] = {}
        self.ping_last: dict[str, float] = {}
        self.frozen: set[str] = set()
        self.notice_log: list[dict[str, Any]] = []
        self.give_windows: list[dict[str, Any]] = []
        self.help_offers: list[dict[str, Any]] = []
        self.camps: dict[str, dict[str, Any]] = {}
        self.camp_rsvps: list[dict[str, Any]] = []
        self.thanks: list[dict[str, Any]] = []
        self.guest_tokens: dict[str, str] = {}
        self.rare_watch: dict[str, list[str]] = {}
        self.disaster_mode: dict[str, bool] = {"public": False}
        self.festival_hush: dict[str, bool] = {"public": False}
        self.hospital_qr: dict[str, dict[str, Any]] = {}
        self.fcm_tokens: dict[str, str] = {}
        self.checkins: list[dict[str, Any]] = []
        self.bank_transfers: list[dict[str, Any]] = []
        self.nss_hours: list[dict[str, Any]] = []
        self.reflection_log: list[dict[str, Any]] = []
        self.night_mode: dict[str, bool] = {}  # User ID -> night mode preference
        self.feature_flags: dict[str, bool] = {
            "hindi_night_mode_enabled": True,
            "low_battery_strip_enabled": True,
            "dead_button_honesty_enabled": True,
            "bag_progress_visual_enabled": True,
            "surgeon_waiting_pulse_enabled": True,
            "two_attendant_lock_enabled": True,
            "language_bridge_enabled": True,
            "heatmap_visualization_enabled": True,
        }
        self.tenants: dict[str, dict[str, Any]] = {
            "public": {"id": "public", "name": "Public India", "logo": "", "color": "#C42B4A", "subtitle": "blood help nearby"}
        }
        if not self._load():
            self._seed()
            self.save()

    def _seed(self) -> None:
        cfg = load_config()
        oid = "owner-1"
        self.users[oid] = {
            "id": oid,
            "email": cfg["owner_email"],
            "role": "owner",
            "tenant_id": "public",
            "phone": "",
            "display_name": "Owner",
            "language": "en",
            "night_mode": False,
            "fasting_hold": False,
            "fever_hold": False,
        }
        self.directory.append(
            {
                "id": "dir-sskm",
                "kind": "hospital",
                "name": "SSKM Hospital",
                "state": "West Bengal",
                "district": "Kolkata",
                "phone": "033-22041100",
                "hours": "00:00-24:00",
                "lat": 22.539,
                "lng": 88.342,
                "open_now": True,
            }
        )
        self.directory.append(
            {
                "id": "dir-howrah",
                "kind": "blood_bank",
                "name": "Howrah Blood Centre",
                "state": "West Bengal",
                "district": "Howrah",
                "phone": "033-26412000",
                "hours": "08:00-20:00",
                "lat": 22.595,
                "lng": 88.310,
                "open_now": True,
            }
        )
        # Demo donor so a first-run map is not empty.
        aid = "demo-arjun"
        self.users[aid] = {
            "id": aid,
            "email": "arjun@sahayak.local",
            "role": "user",
            "tenant_id": "public",
            "phone": "9000000001",
            "display_name": "Arjun",
            "language": "en",
        }
        self.donors[aid] = {
            "id": aid,
            "blood_group": "O+",
            "lat": 22.58,
            "lng": 88.36,
            "available": True,
            "self_hold": False,
            "phone": "9000000001",
            "verified_group": True,
            "component_ok": "whole",
            "fasting_hold": False,
            "fever_hold": False,
            "woman": False,
            "language": "en",
        }

    def _dump(self) -> dict[str, Any]:
        return {
            "users": self.users,
            "tokens": self.tokens,
            "donors": self.donors,
            "requests": self.requests,
            "directory": self.directory,
            "family_rings": self.family_rings,
            "society_rings": self.society_rings,
            "ping_last": self.ping_last,
            "frozen": list(self.frozen),
            "notice_log": self.notice_log[-500:],
            "give_windows": self.give_windows,
            "help_offers": self.help_offers,
            "camps": self.camps,
            "camp_rsvps": self.camp_rsvps,
            "thanks": self.thanks,
            "guest_tokens": self.guest_tokens,
            "rare_watch": self.rare_watch,
            "disaster_mode": self.disaster_mode,
            "festival_hush": self.festival_hush,
            "hospital_qr": self.hospital_qr,
            "fcm_tokens": self.fcm_tokens,
            "checkins": self.checkins,
            "bank_transfers": self.bank_transfers,
            "nss_hours": self.nss_hours,
            "reflection_log": self.reflection_log[-200:],
            "night_mode": self.night_mode,
            "feature_flags": self.feature_flags,
            "tenants": self.tenants,
        }

    def save(self) -> None:
        snapshot = self._dump()
        save_all({k: json.dumps(v, default=str) for k, v in snapshot.items()})

    def _load(self) -> bool:
        raw_rows = load_all()
        if not raw_rows and _LEGACY_DATA.exists():
            # One-time migration: carry forward the old JSON file into the database.
            try:
                legacy = json.loads(_LEGACY_DATA.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                legacy = None
            if legacy:
                save_all({k: json.dumps(v, default=str) for k, v in legacy.items()})
                raw_rows = load_all()
        if not raw_rows:
            return False
        raw = {k: json.loads(v) for k, v in raw_rows.items()}
        self.users = raw.get("users") or {}
        self.tokens = raw.get("tokens") or {}
        self.donors = raw.get("donors") or {}
        self.requests = raw.get("requests") or {}
        self.directory = raw.get("directory") or []
        self.family_rings = raw.get("family_rings") or {}
        self.society_rings = raw.get("society_rings") or {}
        self.ping_last = {k: float(v) for k, v in (raw.get("ping_last") or {}).items()}
        self.frozen = set(raw.get("frozen") or [])
        self.notice_log = raw.get("notice_log") or []
        self.give_windows = raw.get("give_windows") or []
        self.help_offers = raw.get("help_offers") or []
        self.camps = raw.get("camps") or {}
        self.camp_rsvps = raw.get("camp_rsvps") or []
        self.thanks = raw.get("thanks") or []
        self.guest_tokens = raw.get("guest_tokens") or {}
        self.rare_watch = raw.get("rare_watch") or {}
        self.disaster_mode = raw.get("disaster_mode") or {"public": False}
        self.festival_hush = raw.get("festival_hush") or {"public": False}
        self.hospital_qr = raw.get("hospital_qr") or {}
        self.fcm_tokens = raw.get("fcm_tokens") or {}
        self.checkins = raw.get("checkins") or []
        self.bank_transfers = raw.get("bank_transfers") or []
        self.nss_hours = raw.get("nss_hours") or []
        self.reflection_log = raw.get("reflection_log") or []
        self.night_mode = raw.get("night_mode") or {}
        self.feature_flags = raw.get("feature_flags") or self.feature_flags
        if raw.get("tenants"):
            self.tenants = raw["tenants"]
        return bool(self.users)

    def _login_key(self, *, email: str = "", phone: str = "") -> str:
        digits = "".join(c for c in phone if c.isdigit())
        if len(digits) >= 10:
            return "m:" + digits[-10:]
        em = (email or "").strip().lower()
        return "e:" + em if em else ""

    def issue_otp(self, *, email: str = "", phone: str = "") -> str | None:
        key = self._login_key(email=email, phone=phone)
        if not key:
            return None
        now = time.time()
        hits = [t for t in self.otp_hits.get(key, []) if now - t < 3600]
        if len(hits) >= 8:
            return None
        hits.append(now)
        self.otp_hits[key] = hits
        code = "123456" if load_config()["otp"]["echo_in_dev"] else f"{secrets.randbelow(1000000):06d}"
        ttl = float(load_config()["otp"]["ttl_seconds"])
        self.otps[key] = (str(code), time.time() + ttl)
        return str(code)

    def verify_otp(self, *, email: str = "", phone: str = "", code: str) -> dict[str, Any] | None:
        key = self._login_key(email=email, phone=phone)
        if not key:
            return None
        row = self.otps.get(key)
        if not row:
            return None
        saved, exp = row
        if time.time() > exp or saved != code:
            return None
        digits = "".join(c for c in phone if c.isdigit())[-10:] if phone else ""
        em = (email or "").strip().lower()
        user = None
        if key.startswith("m:"):
            user = next((u for u in self.users.values() if "".join(c for c in str(u.get("phone") or "") if c.isdigit())[-10:] == digits), None)
        else:
            user = next((u for u in self.users.values() if (u.get("email") or "").lower() == em), None)
        if not user:
            uid = str(uuid.uuid4())
            user = {
                "id": uid,
                "email": em or f"{digits}@mobile.sahayak.local",
                "role": "user",
                "tenant_id": "public",
                "phone": digits,
                "display_name": (em.split("@")[0] if em else digits),
                "language": "en",
            }
            self.users[uid] = user
        elif digits and not user.get("phone"):
            user["phone"] = digits
        token = secrets.token_urlsafe(32)
        self.tokens[token] = user["id"]
        self.save()
        return {**user, "token": token}

    def user_by_token(self, token: str) -> dict[str, Any] | None:
        uid = self.tokens.get(token)
        if not uid:
            return None
        return self.users.get(uid)

    def delete_user(self, uid: str) -> None:
        self.users.pop(uid, None)
        self.donors.pop(uid, None)
        self.family_rings.pop(uid, None)
        self.rare_watch.pop(uid, None)
        self.fcm_tokens.pop(uid, None)
        self.frozen.discard(uid)
        self.tokens = {t: i for t, i in self.tokens.items() if i != uid}
        self.save()


STORE = MemoryStore()
