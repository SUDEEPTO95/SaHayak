"""SaHayak middleware HTTP. Frontend uses /v1 only."""
from __future__ import annotations

import os
import secrets
from typing import Any

from fastapi import Depends, FastAPI, Header, HTTPException, Query, Request
from fastapi.responses import HTMLResponse, JSONResponse, PlainTextResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path

import time

from pydantic import BaseModel, Field

from app.config_loader import load_config
from app.domain.compatibility import is_compatible
from app.domain.matching import haversine_km, rank_donors
from app.domain.kitchen import after_send, walk_to_door
from app.domain.blocks import block_for, BLOCKS
from app.domain.easy import (
    clean_notebook_person,
    ensure_night_places,
    hospital_key,
    is_night_open,
    ride_expires,
    same_night_mates,
    window_alive,
)
from app.domain.orchestrate_blood_request import SAGA_STEPS
from app.domain.run_saga import RunBloodRequestSaga
from app.notify import notify
from app.store import STORE

cfg = load_config()
app = FastAPI(title=cfg["product_name"], version="1.0.0")
_cors_origins = [
    origin.strip()
    for origin in os.getenv("SAHAYAK_CORS_ORIGINS", "http://127.0.0.1:8080,http://localhost:8080").split(",")
    if origin.strip()
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

HUMAN_ERRORS = {
    "missing_token": "Please sign in again.",
    "invalid_token": "That session ended. Sign in with email.",
    "account_frozen": "This account is paused. Write to the owner.",
    "invalid_otp": "That code did not match. Send a new one.",
    "seeker_throttle": "Pause. Too many open requests today.",
    "not_found": "We could not find that.",
    "no_units_left": "Those units are already promised.",
    "forbidden": "This is for hospitals or the owner — not the two home buttons.",
    "owner_only": "Only the product owner can do this.",
    "outside_station_window": "You are too far from that station window.",
    "camp_unavailable": "That camp is not open.",
    "no_qr": "No poster for that code.",
    "no_camp": "No such camp.",
    "expired_or_missing": "This family link expired or was never created.",
    "otp_rate": "Please wait. Too many codes for this email this hour.",
    "need_guardian": "This request is for a child. An adult name is required.",
    "missing_login": "Type your email or a 10-digit mobile number.",
    "bad_notebook": "Need a short name and a real blood group.",
    "notebook_full": "Eight names is enough. Remove one first.",
    "need_hospital": "Type the hospital name first — just the name, like SSKM.",
    "undo_late": "The two-minute undo window has ended. Stay on this page.",
    "undo_locked": "Someone already promised a bag. We cannot undo.",
    "not_yours": "This request is not yours to change.",
    "not_a_donor": "You are not registered as a donor yet. Save your blood group first.",
    "hold_active": "You have a hold active. Rest and come back later.",
    "invalid_fcm_token": "That notification device token is invalid.",
}

SAGA_HUMAN = {
    "merge_twins": "Checked this is not a duplicate.",
    "notify_family_ring": "Told your Family Ring first.",
    "notify_society_ring": "Told your society, if you opted in.",
    "match_nearest_compatible": "Looked for the nearest compatible donor.",
    "notify_public_ping_rest": "Pinged nearby people who have not been pinged in 24 hours.",
    "wait_or_last_unit": "If the city is empty, we escalate to banks.",
    "first_accept_lock": "The first accept locks one unit.",
    "units_progress": "Units fill one by one.",
    "thank_quietly": "Thanks stay private. No public leaderboard.",
    "festival_hush_hold_public": "Festival hush: Family Ring first. Public ping waits.",
    "women_first_ping": "Women donors heard first, if they opted in.",
}


@app.exception_handler(HTTPException)
async def human_http_error(request: Request, exc: HTTPException) -> JSONResponse:
    code = exc.detail if isinstance(exc.detail, str) else "error"
    lang = request.headers.get("accept-language") or "en"
    human = HUMAN_ERRORS.get(str(code), "Something went wrong. Try once more.")
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": code,
            "human": human,
            "block": block_for(str(code), status=exc.status_code, language=lang),
        },
    )


def current_user(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(401, "missing_token")
    token = authorization.split(" ", 1)[1]
    user = STORE.user_by_token(token)
    if not user:
        raise HTTPException(401, "invalid_token")
    if user["id"] in STORE.frozen:
        raise HTTPException(403, "account_frozen")
    return user


class OtpRequest(BaseModel):
    email: str = ""
    phone: str = ""
    channel: str = "email"


class OtpVerify(BaseModel):
    email: str = ""
    phone: str = ""
    code: str
    channel: str = "email"


class DonorProfile(BaseModel):
    blood_group: str
    lat: float
    lng: float
    available: bool = True
    self_hold: bool = False
    phone: str = ""
    verified_group: bool = False
    component_ok: str = "whole"
    last_donation_at: float | None = None
    city: str = ""
    woman: bool = False
    fasting_hold: bool = False
    fever_hold: bool = False
    language: str = "en"


class MePatch(BaseModel):
    phone: str | None = None
    display_name: str | None = None
    language: str | None = None
    city: str | None = None


class MatchQuery(BaseModel):
    recipient_group: str
    lat: float
    lng: float
    radius_km: float | None = None
    component: str = "whole"
    urgency: str = "critical"


class BloodRequestIn(BaseModel):
    recipient_group: str
    component: str = "whole"
    units: int = Field(default=1, ge=1, le=20)
    lat: float
    lng: float
    hospital_name: str = ""
    ward: str = ""
    bed: str = ""
    urgency: str = "critical"
    minor_patient: bool = False
    guardian_name: str = ""
    society_id: str = ""
    hospital_qr: str = ""
    language: str = "en"
    station_place: str = ""
    idempotency_key: str = ""
    lane: str = "sos"
    due_on: str = ""
    women_first: bool = False


@app.get("/v1/blocks")
def list_blocks() -> dict[str, Any]:
    """Copy for pause cards. UI may use this or the bundle in block.js."""
    return {"blocks": BLOCKS, "stay": True, "human": "One OK. You stay on the same page."}


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "product": cfg["product_name"], "human": "SaHayak is awake."}


@app.get("/v1/meta")
def meta() -> dict[str, Any]:
    return {
        "product": cfg["product_name"],
        "tagline": cfg.get("tagline", "blood help nearby"),
        "flags": cfg["flags"],
        "blood_groups": cfg["blood_groups"],
        "components": cfg["components"],
        "radius_km_steps": cfg["matching"]["radius_km_steps"],
        "saga_steps": list(SAGA_STEPS),
        "home_actions": ["need_blood", "i_can_donate"],
        "cities": cfg.get("cities", {}),
        "stations": cfg.get("stations", {}),
        "human": "SaHayak is blood help nearby. Home is only Need blood and I can donate.",
    }


@app.post("/v1/auth/otp/request")
def otp_request(body: OtpRequest) -> dict[str, Any]:
    digits = "".join(c for c in body.phone if c.isdigit())
    if not (body.email or "").strip() and len(digits) < 10:
        raise HTTPException(400, "missing_login")
    code = STORE.issue_otp(email=body.email, phone=body.phone)
    if code is None:
        raise HTTPException(429, "otp_rate")
    channel = "mobile" if body.channel == "mobile" or (body.phone and not body.email) else "email"
    out: dict[str, Any] = {
        "ok": True,
        "channel": channel,
        "human": (
            "A quiet code is ready on this computer. Live SMS is off until a gateway is paid. We never read SMS on your phone."
            if channel == "mobile"
            else "A quiet code is on the way. We never ask for SMS permission."
        ),
    }
    if cfg["otp"]["echo_in_dev"] and os.getenv("SAHAYAK_ENV", "development").lower() != "production":
        out["dev_otp"] = code
    return out


@app.post("/v1/auth/otp/verify")
def otp_verify(body: OtpVerify) -> dict[str, Any]:
    user = STORE.verify_otp(email=body.email, phone=body.phone, code=body.code)
    if not user:
        raise HTTPException(400, "invalid_otp")
    return {**user, "human": "You are in. Two choices: need blood, or I can donate."}


@app.get("/v1/me")
def me(user: dict = Depends(current_user)) -> dict[str, Any]:
    from app.domain.calm_features import donor_self_hold_reason, should_use_night_mode
    
    donor = STORE.donors.get(user["id"])
    donor_hold = None
    if donor:
        donor_hold = donor_self_hold_reason(donor)
    
    night_mode = should_use_night_mode(user)
    
    user_clean = {k: v for k, v in user.items() if k != "token"}
    
    return {
        "user": user_clean,
        "donor": {k: v for k, v in (donor or {}).items() if k != "phone"} if donor else None,
        "donor_hold_reason": donor_hold,
        "family_ring": STORE.family_rings.get(user["id"], []),
        "family_notebook": STORE.users.get(user["id"], {}).get("family_notebook") or [],
        "fcm_registered": user["id"] in STORE.fcm_tokens,
        "night_mode_active": night_mode,
        "features_available": {
            "bag_progress_visual": STORE.feature_flags.get("bag_progress_visual_enabled", False),
            "surgeon_waiting_pulse": STORE.feature_flags.get("surgeon_waiting_pulse_enabled", False),
            "language_bridge": STORE.feature_flags.get("language_bridge_enabled", False),
            "heatmap_visualization": STORE.feature_flags.get("heatmap_visualization_enabled", False),
        },
        "human": "This is you. Matching never lives on the phone.",
    }


@app.post("/v1/me")
def patch_me(body: MePatch, user: dict = Depends(current_user)) -> dict[str, Any]:
    row = STORE.users[user["id"]]
    data = body.model_dump(exclude_none=True)
    row.update(data)
    STORE.save()
    return {"ok": True, "user": row, "human": "Saved. You can change this any time."}


@app.delete("/v1/me")
def delete_me(user: dict = Depends(current_user)) -> dict[str, Any]:
    if user.get("role") == "owner":
        raise HTTPException(403, "owner_only")
    STORE.delete_user(user["id"])
    return {"ok": True, "human": "Your account and donor card are gone from SaHayak."}


@app.get("/v1/inbox")
def inbox(user: dict = Depends(current_user)) -> dict[str, Any]:
    """Minute-to-minute notices without paid FCM. Same log FCM would send."""
    rows = [n for n in STORE.notice_log if n.get("target_id") == user["id"]]
    return {
        "notices": rows[-50:],
        "fcm_enabled": cfg["flags"]["fcm_enabled"],
        "human": "Quiet inbox. Same words a push would have sent — without a Google bill.",
    }


def _expire_if_needed(rec: dict[str, Any]) -> dict[str, Any]:
    ttl_h = float(cfg["requests"]["ttl_hours"])
    created = float(rec.get("created_at", time.time()))
    if rec.get("status") == "open" and (time.time() - created) > ttl_h * 3600:
        rec["status"] = "expired"
    return rec


@app.post("/v1/donors/me")
def upsert_donor(body: DonorProfile, user: dict = Depends(current_user)) -> dict[str, Any]:
    from app.domain.validation import validate_donor_profile_extended, get_error_http_status
    
    # Validate extended fields
    is_valid, error_code = validate_donor_profile_extended(body.model_dump())
    if not is_valid:
        http_status = get_error_http_status(error_code or "")
        raise HTTPException(http_status, error_code or "invalid_donor_profile")
    
    donor_data = body.model_dump()
    # Ensure hold flags don't contradict
    if donor_data.get("fasting_hold") and donor_data.get("fever_hold"):
        raise HTTPException(400, "cannot_hold_both")
    
    STORE.donors[user["id"]] = {"id": user["id"], **donor_data}
    if body.phone:
        STORE.users[user["id"]]["phone"] = body.phone
    if body.language:
        STORE.users[user["id"]]["language"] = body.language
    
    STORE.save()
    
    hi = (body.language or user.get("language", "en")).lower().startswith("hi")
    hold_msg = ""
    if body.fasting_hold:
        hold_msg = " (आप आराम कर रहे हैं)" if hi else " (You're resting)"
    elif body.fever_hold:
        hold_msg = " (बुख़ार है)" if hi else " (You have fever)"
    
    human = f"Saved{hold_msg}. We will not ping you if you turn on self-hold." if not hi else f"सेव हो गया{hold_msg}। अगर आप होल्ड करेंगे तो आपको पिंग नहीं करेंगे।"
    
    return {"ok": True, "human": human}


@app.post("/v1/match/nearby")
def match_nearby(body: MatchQuery, user: dict = Depends(current_user)) -> dict[str, Any]:
    steps = cfg["matching"]["radius_km_steps"]
    radius = body.radius_km if body.radius_km is not None else float(steps[0])
    ranked = rank_donors(
        recipient_group=body.recipient_group,
        origin_lat=body.lat,
        origin_lng=body.lng,
        donors=list(STORE.donors.values()),
        radius_km=radius,
    )
    return {"donors": ranked, "radius_km": radius, "component": body.component, "human": "Nearest compatible first. Phones are not in this list."}


@app.post("/v1/need/parse")
def parse_need(body: dict[str, str], user: dict = Depends(current_user)) -> dict[str, Any]:
    """WhatsApp paste → form fields. Does not notify anyone."""
    from app.graph.nodes import parse_need_message

    parsed = parse_need_message(body.get("text") or "")
    hi = (body.get("language") or user.get("language") or "en").lower().startswith("hi")
    if hi:
        human = "फॉर्म भर दिया। अभी किसी को नहीं बताया। सही लगे तो भेजें दबाएँ।"
    else:
        human = "Filled the form. Nobody has been told yet. Check it, then tap Send."
    return {"parsed": parsed, "sent": False, "human": human}


@app.post("/v1/need/slip")
def parse_slip(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    """Hospital paper: type what you see + optional photo name. Never notifies. Picture is not uploaded."""
    from app.graph.nodes import parse_need_message

    blob = " ".join(
        str(x) for x in (body.get("text") or "", body.get("filename") or "", body.get("caption") or "") if x
    )
    parsed = parse_need_message(blob)
    has_photo = bool(body.get("has_photo") or body.get("filename"))
    STORE.users[user["id"]]["last_slip"] = {
        "filename": str(body.get("filename") or "")[:80],
        "has_photo": has_photo,
        "at": time.time(),
    }
    STORE.save()
    hi = (body.get("language") or user.get("language") or "en").lower().startswith("hi")
    if hi:
        human = "अस्पताल की पर्ची से फॉर्म भरा। फोटो इस डिवाइस पर रहती है। अभी किसी को नहीं बताया।"
    else:
        human = "Filled from the hospital paper. The photo stays on this device. Nobody has been told yet."
    if not parsed.get("recipient_group") and not parsed.get("hospital_name"):
        human = (
            "पर्ची की तीन बातें लिखें: ग्रुप, यूनिट, अस्पताल। अभी किसी को नहीं बताया।"
            if hi
            else "Type the three words from the paper: group, units, hospital. Nobody has been told yet."
        )
    return {"parsed": parsed, "sent": False, "has_photo": has_photo, "human": human}


@app.post("/v1/blood-requests")
def create_request(body: BloodRequestIn, user: dict = Depends(current_user)) -> dict[str, Any]:
    from app.domain.validation import validate_blood_request_enhanced, get_error_http_status
    
    # Validate enhanced fields
    is_valid, error_code = validate_blood_request_enhanced(body.model_dump())
    if not is_valid:
        http_status = get_error_http_status(error_code or "")
        raise HTTPException(http_status, error_code or "invalid_request")
    
    lane = (body.lane or "sos").lower()
    if lane not in ("sos", "regular"):
        lane = "sos"
    if body.minor_patient and not (body.guardian_name or "").strip():
        raise HTTPException(400, "need_guardian")
    open_count = sum(
        1 for r in STORE.requests.values() if r["seeker_id"] == user["id"] and r["status"] == "open"
    )
    if open_count >= int(cfg["requests"]["max_open_per_user_per_day"]):
        raise HTTPException(429, "seeker_throttle")
    for existing in STORE.requests.values():
        if (
            existing["status"] == "open"
            and existing["hospital_name"] == body.hospital_name
            and existing["recipient_group"] == body.recipient_group
            and existing["component"] == body.component
            and (existing.get("lane") or "sos") == lane
        ):
            return {
                "merged": True,
                "twin": True,
                "same_emergency": True,
                "request": existing,
                "human": after_send(existing, merged=True, language=body.language),
            }
    rid = body.idempotency_key or f"req-{len(STORE.requests)+1}"
    rec = {
        "id": rid,
        "seeker_id": user["id"],
        "seeker_phone": user.get("phone") or "",
        "seeker_name": user.get("display_name") or "",
        "tenant_id": user.get("tenant_id", "public"),
        "status": "open",
        "units_needed": body.units,
        "units_accepted": 0,
        "remaining_lock": body.units,
        "created_at": time.time(),
        "language": body.language,
        **body.model_dump(),
        "lane": lane,
    }
    if body.hospital_qr and body.hospital_qr in STORE.hospital_qr:
        rec["hospital_verified"] = True
        rec["hospital_name"] = STORE.hospital_qr[body.hospital_qr].get("hospital_name", rec["hospital_name"])
    rec = RunBloodRequestSaga().run(rec)
    guest = f"guest-{secrets.token_urlsafe(24)}"
    STORE.guest_tokens[guest] = rid
    rec["guest_token"] = guest
    rec["guest_url"] = f"/guest/{guest}"
    STORE.requests[rid] = rec
    STORE.save()
    return {
        "merged": False,
        "request": rec,
        "orchestration": rec.get("saga"),
        "human": after_send(rec, merged=False, language=body.language),
        "guest_url": rec.get("guest_url"),
        "status_strip": after_send(rec, merged=False, language=body.language),
        "undo_seconds": 120,
    }


@app.post("/v1/blood-requests/{request_id}/undo")
def undo_request(request_id: str, user: dict = Depends(current_user)) -> dict[str, Any]:
    rec = STORE.requests.get(request_id)
    if not rec:
        raise HTTPException(404, "not_found")
    if rec.get("seeker_id") != user["id"]:
        raise HTTPException(403, "not_yours")
    if int(rec.get("units_accepted") or 0) > 0:
        raise HTTPException(409, "undo_locked")
    if time.time() - float(rec.get("created_at") or 0) > 120:
        raise HTTPException(400, "undo_late")
    rec["status"] = "cancelled"
    rec["undone"] = True
    STORE.save()
    return {"ok": True, "request": rec, "human": "Undone. Nobody new will be told. You stay on this page."}


@app.get("/v1/blood-requests/{request_id}/story")
def request_story(request_id: str, user: dict = Depends(current_user)) -> dict[str, Any]:
    rec = STORE.requests.get(request_id)
    if not rec:
        raise HTTPException(404, "not_found")
    rec = RunBloodRequestSaga().maybe_escalate(_expire_if_needed(rec))
    lines = [SAGA_HUMAN.get(s, s) for s in rec.get("saga", [])]
    wait_left = max(0, int(float(rec.get("pending_escalate_at", 0)) - time.time()))
    return {
        "lines": lines,
        "last_unit": rec.get("last_unit"),
        "escalate_in_seconds": wait_left if not rec.get("last_unit") else 0,
        "guest_token": rec.get("guest_token"),
        "units_progress": f"{rec.get('units_accepted', 0)}/{rec.get('units_needed', 0)}",
        "human": " ".join(lines) if lines else "This request has no story yet.",
    }


@app.get("/v1/blood-requests/mine")
def my_requests(user: dict = Depends(current_user)) -> dict[str, Any]:
    rows = []
    for r in STORE.requests.values():
        if r["seeker_id"] != user["id"]:
            continue
        rec = RunBloodRequestSaga().maybe_escalate(_expire_if_needed(r))
        public = {k: v for k, v in rec.items() if k != "seeker_phone"}
        rows.append(public)
    return {"requests": rows}


@app.get("/v1/blood-requests/open")
def open_requests(user: dict = Depends(current_user)) -> dict[str, Any]:
    from app.domain.calm_features import bag_progress_visual, surgeon_still_waiting, donor_self_hold_reason
    
    donor = STORE.donors.get(user["id"])
    out = []
    for rec in STORE.requests.values():
        rec = RunBloodRequestSaga().maybe_escalate(_expire_if_needed(rec))
        if rec.get("status") != "open":
            continue
        if rec.get("lane") == "regular":
            continue
        jitter = 0.008
        item = {
            "id": rec["id"],
            "recipient_group": rec.get("recipient_group"),
            "component": rec.get("component"),
            "hospital_name": rec.get("hospital_name"),
            "ward": rec.get("ward"),
            "units_progress": f"{rec['units_accepted']}/{rec['units_needed']}",
            "lat": round(float(rec.get("lat") or 0) + jitter, 4),
            "lng": round(float(rec.get("lng") or 0) - jitter / 2, 4),
            "language": rec.get("language"),
            "phone": None,
            "bag_progress": bag_progress_visual(rec),
            "surgeon_waiting": surgeon_still_waiting(rec),
        }
        if donor:
            item["compatible"] = is_compatible(str(rec.get("recipient_group")), str(donor.get("blood_group")))
        out.append(item)
    
    # Add donor hold info if applicable
    donor_hold = None
    if donor:
        donor_hold = donor_self_hold_reason(donor)
    
    return {
        "requests": out,
        "donor_hold_reason": donor_hold,
        "human": "Open needs nearby. Phone stays hidden until you accept."
    }


@app.post("/v1/blood-requests/{request_id}/accept")
def accept_request(request_id: str, user: dict = Depends(current_user)) -> dict[str, Any]:
    from app.domain.calm_features import bag_progress_visual, walk_to_door_visual
    
    rec = STORE.requests.get(request_id)
    if rec:
        rec = _expire_if_needed(rec)
    if not rec or rec["status"] != "open":
        raise HTTPException(404, "not_found")
    if rec["remaining_lock"] <= 0:
        raise HTTPException(409, "no_units_left")
    rec["remaining_lock"] -= 1
    rec["units_accepted"] += 1
    if rec["remaining_lock"] <= 0:
        rec["status"] = "fulfilled"
    donor = STORE.donors.get(user["id"], {})
    rec["accepted_by"] = rec.get("accepted_by", []) + [user["id"]]
    STORE.save()
    family_phone = rec.get("seeker_phone") or ""
    notify(
        "accept",
        rec["seeker_id"],
        rec["id"],
        f"A donor accepted. Progress {rec['units_accepted']}/{rec['units_needed']}. Donor first name: {user.get('display_name') or 'donor'}.",
    )
    lang = user.get("language") or rec.get("language") or "en"
    walk = walk_to_door(rec, language=lang)
    walk_visual = walk_to_door_visual(rec, language=lang)
    bag_progress = bag_progress_visual(rec)
    return {
        "ok": True,
        "units_progress": f"{rec['units_accepted']}/{rec['units_needed']}",
        "phone": family_phone,
        "ward": rec.get("ward"),
        "bed": rec.get("bed"),
        "hospital_name": rec.get("hospital_name"),
        "meet": "blood_bank_door",
        "walk_line": walk,
        "walk_visual": walk_visual,
        "bag_progress": bag_progress,
        "human": f"{walk} Progress {rec['units_accepted']}/{rec['units_needed']}. Family phone is now for you only.",
    }


@app.get("/v1/directory")
def directory(
    kind: str | None = None,
    state: str | None = None,
    night: bool = Query(default=False),
    user: dict = Depends(current_user),
) -> dict[str, Any]:
    if ensure_night_places(STORE.directory):
        STORE.save()
    rows = list(STORE.directory)
    if kind:
        rows = [r for r in rows if r.get("kind") == kind]
    if state:
        rows = [r for r in rows if r.get("state") == state]
    if night:
        rows = [r for r in rows if is_night_open(r)]
        human = "Places listed as open after 10pm. Official hours only — not a live door sensor."
    else:
        human = "Official hours only. We do not scrape the web."
    return {"entries": rows, "night": night, "human": human}


@app.post("/v1/directory")
def add_directory(entry: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] not in ("owner", "tenant_admin"):
        raise HTTPException(403, "forbidden")
    STORE.directory.append(entry)
    STORE.save()
    return {"ok": True}


@app.post("/v1/owner/freeze/{user_id}")
def freeze_user(user_id: str, user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] != "owner":
        raise HTTPException(403, "owner_only")
    STORE.frozen.add(user_id)
    STORE.save()
    return {"ok": True}


@app.post("/v1/family-ring")
def family_ring(members: list[str], user: dict = Depends(current_user)) -> dict[str, Any]:
    STORE.family_rings[user["id"]] = members[:5]
    STORE.save()
    return {"ok": True, "count": len(STORE.family_rings[user["id"]]), "human": "Family Ring saved. They hear first."}


@app.get("/v1/family-notebook")
def get_notebook(user: dict = Depends(current_user)) -> dict[str, Any]:
    people = STORE.users[user["id"]].get("family_notebook") or []
    return {
        "people": people,
        "human": "Only you see these names. Tap one when Need blood asks for a group.",
    }


@app.post("/v1/family-notebook")
def save_notebook(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    row = STORE.users[user["id"]]
    people = list(row.get("family_notebook") or [])
    if body.get("clear"):
        people = []
    elif body.get("remove") is not None:
        try:
            i = int(body["remove"])
            if 0 <= i < len(people):
                people.pop(i)
        except (TypeError, ValueError):
            pass
    elif body.get("people") is not None:
        people = []
        for p in body.get("people") or []:
            item = clean_notebook_person(str(p.get("who") or ""), str(p.get("group") or ""))
            if item:
                people.append(item)
            if len(people) >= 8:
                break
    else:
        item = clean_notebook_person(str(body.get("who") or ""), str(body.get("group") or ""))
        if not item:
            raise HTTPException(400, "bad_notebook")
        if len(people) >= 8:
            raise HTTPException(400, "notebook_full")
        people.append(item)
    row["family_notebook"] = people
    STORE.save()
    return {"ok": True, "people": people, "human": "Saved. Next time, tap a name — we never put this on a map."}


@app.get("/v1/same-night")
def same_night(hospital: str = "", user: dict = Depends(current_user)) -> dict[str, Any]:
    name = hospital.strip()
    if not name:
        mine = [r for r in STORE.requests.values() if r.get("seeker_id") == user["id"] and r.get("status") == "open"]
        name = (mine[0].get("hospital_name") if mine else "") or ""
    if not name:
        raise HTTPException(400, "need_hospital")
    fake = {"id": "", "hospital_name": name}
    mates = same_night_mates(STORE.requests, fake)
    offers = [
        {"kind": o.get("kind"), "hospital_name": o.get("hospital_name"), "phone": None}
        for o in STORE.help_offers
        if o.get("same_night") and hospital_key(o.get("hospital_name")) == hospital_key(name)
    ]
    n = len(mates)
    if n == 0:
        human = f"No other open family at {name} tonight. You can still offer a wait — phones stay hidden."
    elif n == 1:
        human = f"One other family at {name} tonight. No phones. Offer a shared wait or cab if you want."
    else:
        human = f"{n} other families at {name} tonight. No phones. Offer a shared wait or cab if you want."
    return {"hospital_name": name, "mates": mates, "offers": offers, "count": n, "human": human}


@app.post("/v1/same-night/share")
def same_night_share(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    kind = str(body.get("kind") or "wait")
    if kind not in ("wait", "cab"):
        kind = "wait"
    name = str(body.get("hospital_name") or "").strip()
    rid = str(body.get("request_id") or "")
    if rid and rid in STORE.requests:
        name = STORE.requests[rid].get("hospital_name") or name
    if not name:
        raise HTTPException(400, "need_hospital")
    STORE.help_offers.append(
        {
            "user_id": user["id"],
            "kind": kind,
            "same_night": True,
            "hospital_name": name,
            "request_id": rid,
            "phone": None,
            "created_at": time.time(),
        }
    )
    STORE.save()
    label = "a shared wait" if kind == "wait" else "a shared cab"
    return {"ok": True, "human": f"Offered {label} at {name}. Other families see it without a phone."}


@app.post("/v1/society-ring")
def society_ring(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    sid = str(body.get("society_id", "default-society"))
    STORE.users[user["id"]]["society_id"] = sid
    members = STORE.society_rings.setdefault(sid, [])
    if user["id"] not in members:
        members.append(user["id"])
    STORE.save()
    return {"ok": True, "society_id": sid, "members": members}


@app.post("/v1/give-windows")
def give_window(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    kind = str(body.get("kind") or "station")
    row = {"user_id": user["id"], **body, "kind": kind, "created_at": time.time()}
    if kind == "ride":
        minutes = int(body.get("minutes") or 40)
        corridor = str(body.get("corridor") or body.get("place") or "Sealdah")
        stations = cfg.get("stations") or {}
        if corridor in stations:
            row["station_lat"] = stations[corridor][0]
            row["station_lng"] = stations[corridor][1]
        row["corridor"] = corridor
        row["minutes"] = max(10, min(180, minutes))
        row["expires_at"] = ride_expires(row["minutes"])
        row["phone"] = None
        STORE.give_windows.append(row)
        STORE.save()
        return {
            "ok": True,
            "window": {k: v for k, v in row.items() if k != "user_id"},
            "human": f"This ride only — {corridor} for about {row['minutes']} minutes. Then it disappears. Phone hidden.",
        }
    if body.get("station_lat") is not None and body.get("lat") is not None:
        km = haversine_km(
            float(body["lat"]),
            float(body["lng"]),
            float(body["station_lat"]),
            float(body["station_lng"]),
        )
        row["station_window_ok"] = km <= float(body.get("station_radius_km", 8))
        if not row["station_window_ok"]:
            raise HTTPException(400, "outside_station_window")
    STORE.give_windows.append(row)
    STORE.save()
    return {"ok": True, "window": row, "human": "Give-window posted. People nearby can see you are free."}


@app.get("/v1/give-windows")
def list_give_windows(user: dict = Depends(current_user)) -> dict[str, Any]:
    now = time.time()
    alive = [w for w in STORE.give_windows if window_alive(w, now)]
    mine = [w for w in alive if w.get("user_id") == user["id"]]
    rides = [
        {
            "corridor": w.get("corridor") or w.get("place"),
            "minutes": w.get("minutes"),
            "expires_at": w.get("expires_at"),
            "phone": None,
        }
        for w in alive
        if w.get("kind") == "ride"
    ]
    return {"windows": mine, "rides": rides, "human": "Live rides hide the phone. Dead rides vanish."}


@app.get("/v1/camps")
def list_camps(user: dict = Depends(current_user)) -> dict[str, Any]:
    return {"camps": list(STORE.camps.values())}


@app.post("/v1/help-without-blood")
def help_without_blood(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    row = {"user_id": user["id"], "kind": body.get("kind", "ride"), **body}
    STORE.help_offers.append(row)
    STORE.save()
    return {"ok": True, "human": "Offer saved. This is help without drawing blood."}


@app.post("/v1/hospital-qr")
def hospital_qr(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] not in ("owner", "tenant_admin"):
        raise HTTPException(403, "forbidden")
    code = str(body.get("code") or f"qr-{len(STORE.hospital_qr)+1}")
    STORE.hospital_qr[code] = body
    STORE.hospital_qr[code]["code"] = code
    STORE.save()
    return {"ok": True, "code": code, "poster_text": f"SaHayak ward QR: {code}"}


@app.get("/v1/print-poster/{code}")
def print_poster(code: str, user: dict = Depends(current_user)) -> PlainTextResponse:
    if code not in STORE.hospital_qr:
        raise HTTPException(404, "no_qr")
    text = f"SAHAYAK HOSPITAL POSTER\nScan / enter code: {code}\n{STORE.hospital_qr[code]}\n"
    return PlainTextResponse(text)


@app.post("/v1/checkin")
def checkin(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    row = {"user_id": user["id"], **body}
    STORE.checkins.append(row)
    STORE.save()
    return {"ok": True, "human": "Your family can see you are on the way. Pin stays approximate."}


@app.post("/v1/rare-watch")
def rare_watch(groups: list[str], user: dict = Depends(current_user)) -> dict[str, Any]:
    STORE.rare_watch[user["id"]] = groups
    STORE.save()
    return {"ok": True, "human": "If this rare group is needed in your state, we will tell you quietly."}


@app.post("/v1/language")
def set_language(body: dict[str, str], user: dict = Depends(current_user)) -> dict[str, Any]:
    STORE.users[user["id"]]["language"] = body.get("language", "en")
    STORE.save()
    return {"ok": True}


@app.post("/v1/disaster-mode")
def disaster_mode(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] not in ("owner", "tenant_admin"):
        raise HTTPException(403, "forbidden")
    tid = body.get("tenant_id", user.get("tenant_id", "public"))
    STORE.disaster_mode[tid] = bool(body.get("on", True))
    STORE.save()
    return {"ok": True, "disaster_mode": STORE.disaster_mode, "human": "Disaster switch saved. Citizen home still two buttons."}


@app.post("/v1/festival-hush")
def festival_hush(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] not in ("owner", "tenant_admin"):
        raise HTTPException(403, "forbidden")
    tid = body.get("tenant_id", user.get("tenant_id", "public"))
    STORE.festival_hush[tid] = bool(body.get("on", True))
    STORE.save()
    on = STORE.festival_hush[tid]
    return {
        "ok": True,
        "festival_hush": STORE.festival_hush,
        "human": "Festival hush on. Family Ring first. Public ping waits." if on else "Festival hush off. Usual matching.",
    }


@app.get("/v1/grace-date")
def grace_date(user: dict = Depends(current_user)) -> dict[str, Any]:
    days = int(cfg["cooling"]["days_after_whole_blood"])
    return {
        "next_eligible_days_after_donation": days,
        "message": "Informational only, not medical advice.",
        "human": f"After whole blood, many people wait about {days} days. This is not medical advice.",
    }


@app.post("/v1/stand-in")
def stand_in(body: dict[str, str], user: dict = Depends(current_user)) -> dict[str, Any]:
    STORE.users[user["id"]]["stand_in_user_id"] = body.get("stand_in_user_id") or body.get("name") or ""
    STORE.save()
    return {"ok": True, "human": "If you cannot go, this person may tap I can go for your family only."}


@app.post("/v1/night-mode")
def set_night_mode(body: dict[str, bool], user: dict = Depends(current_user)) -> dict[str, Any]:
    from app.domain.validation import validate_night_mode, get_error_http_status
    
    # Validate input
    is_valid, error_code = validate_night_mode(body)
    if not is_valid:
        http_status = get_error_http_status(error_code or "")
        raise HTTPException(http_status, error_code or "invalid_request")
    
    uid = user["id"]
    on = bool(body.get("on", False))
    STORE.night_mode[uid] = on
    STORE.users[uid]["night_mode"] = on
    STORE.save()
    
    hi = (user.get("language", "en") or "en").lower().startswith("hi")
    if on:
        human = "Hindi night mode: huge type, two buttons, gold on black." if hi else "Night mode on. Huge type, gold on black."
    else:
        human = "सामान्य मोड वापस आया।" if hi else "Normal mode restored."
    
    return {"ok": True, "night_mode": on, "human": human}


@app.post("/v1/donors/me/hold")
def donor_hold(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    """Set fasting or fever hold for donor."""
    from app.domain.validation import validate_donor_hold, get_error_http_status
    
    # Validate input
    is_valid, error_code = validate_donor_hold(body)
    if not is_valid:
        http_status = get_error_http_status(error_code or "")
        raise HTTPException(http_status, error_code or "invalid_hold_request")
    
    # Check if user is registered as donor
    if user["id"] not in STORE.donors:
        raise HTTPException(404, "not_a_donor")
    
    donor = STORE.donors[user["id"]]
    fasting = bool(body.get("fasting", False))
    fever = bool(body.get("fever", False))
    
    donor["fasting_hold"] = fasting
    donor["fever_hold"] = fever
    STORE.users[user["id"]]["fasting_hold"] = fasting
    STORE.users[user["id"]]["fever_hold"] = fever
    STORE.save()
    
    # Determine hold reason
    if fasting:
        reason = "fasting"
        human_reason = "Fasting today. Rest and come back when you've eaten."
    elif fever:
        reason = "fever"
        human_reason = "Fever. Get well first. We'll ping you later."
    else:
        reason = "none"
        human_reason = "Hold cleared. You're available again."
    
    hi = (user.get("language", "en") or "en").lower().startswith("hi")
    if hi:
        reason_hi = {
            "fasting": "आज खाली पेट हैं। खाना खा लें, फिर आ जाइए।",
            "fever": "बुख़ार है। ठीक हो जाइए। हम बाद में पूछेंगे।",
            "none": "होल्ड खत्म। अब उपलब्ध हैं।",
        }
        human_reason = reason_hi.get(reason, human_reason)
    
    return {
        "ok": True,
        "donor": {k: v for k, v in donor.items() if k != "phone"},
        "hold_reason": reason,
        "human": human_reason,
    }


@app.get("/v1/feature-flags")
def feature_flags(user: dict = Depends(current_user)) -> dict[str, Any]:
    """Return which features are enabled for UI to use."""
    from app.domain.calm_features import feature_capability_check
    
    flags = feature_capability_check(STORE.feature_flags)
    return {
        "features": flags,
        "human": "These features are available on this platform.",
    }


@app.post("/v1/camps")
def create_camp(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] not in ("owner", "tenant_admin"):
        raise HTTPException(403, "forbidden")
    cid = str(body.get("id") or f"camp-{len(STORE.camps)+1}")
    STORE.camps[cid] = {"id": cid, "status": "open", **body}
    STORE.save()
    return {"ok": True, "camp": STORE.camps[cid]}


@app.post("/v1/camps/{camp_id}/rsvp")
def camp_rsvp(camp_id: str, user: dict = Depends(current_user)) -> dict[str, Any]:
    if camp_id not in STORE.camps or STORE.camps[camp_id].get("status") == "cancelled":
        raise HTTPException(404, "camp_unavailable")
    STORE.camp_rsvps.append({"camp_id": camp_id, "user_id": user["id"]})
    STORE.save()
    return {"ok": True, "human": "Camp seat booked. If rain cancels it, you will see it in Inbox."}


@app.post("/v1/camps/{camp_id}/cancel")
def camp_cancel(camp_id: str, user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] not in ("owner", "tenant_admin"):
        raise HTTPException(403, "forbidden")
    if camp_id not in STORE.camps:
        raise HTTPException(404, "no_camp")
    STORE.camps[camp_id]["status"] = "cancelled"
    for r in STORE.camp_rsvps:
        if r["camp_id"] == camp_id:
            notify("camp_cancel", r["user_id"], camp_id, "Camp cancelled.")
    STORE.save()
    return {"ok": True}


@app.post("/v1/camps/{camp_id}/passport")
def camp_passport(camp_id: str, user: dict = Depends(current_user)) -> dict[str, Any]:
    token = f"pass-{secrets.token_urlsafe(24)}"
    return {"ok": True, "offline_token": token, "camp_id": camp_id}


@app.post("/v1/thanks")
def thanks(body: dict[str, str], user: dict = Depends(current_user)) -> dict[str, Any]:
    STORE.thanks.append({"from": user["id"], **body})
    STORE.save()
    return {"ok": True, "public_leaderboard": False, "human": "Thanks sent privately. No public scoreboard."}


@app.post("/v1/blood-requests/{request_id}/still-need")
def still_need(request_id: str, user: dict = Depends(current_user)) -> dict[str, Any]:
    rec = STORE.requests.get(request_id)
    if not rec:
        raise HTTPException(404, "not_found")
    if rec.get("seeker_id") != user["id"] and user.get("role") not in ("owner", "tenant_admin"):
        raise HTTPException(403, "not_yours")
    rec["status"] = "open"
    rec = RunBloodRequestSaga().run(rec)
    STORE.save()
    return {"ok": True, "request": rec, "human": "Surgeon still waiting. We start again from Family Ring."}


@app.post("/v1/offline-queue")
def offline_queue(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    """Replay a request saved on device when the network returns."""
    payload = BloodRequestIn(**{k: v for k, v in body.items() if k in BloodRequestIn.model_fields})
    return create_request(payload, user)


@app.post("/v1/bank-transfer")
def bank_transfer(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] not in ("owner", "tenant_admin"):
        raise HTTPException(403, "forbidden")
    STORE.bank_transfers.append(body)
    STORE.save()
    return {"ok": True}


@app.post("/v1/nss-hours")
def nss_hours(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] not in ("owner", "tenant_admin"):
        raise HTTPException(403, "forbidden")
    STORE.nss_hours.append(body)
    STORE.save()
    pdf = f"NSS hours certificate\n{body}\n"
    return {"ok": True, "certificate_text": pdf}


@app.post("/v1/fcm-token")
def fcm_token(body: dict[str, str], user: dict = Depends(current_user)) -> dict[str, Any]:
    token = (body.get("token") or "").strip()
    if not token or len(token) > 4096:
        raise HTTPException(400, "invalid_fcm_token")
    STORE.fcm_tokens[user["id"]] = token
    STORE.save()
    return {"ok": True, "fcm_enabled": cfg["flags"]["fcm_enabled"]}


@app.get("/v1/status-card/{request_id}")
def status_card(request_id: str, language: str | None = Query(default=None), user: dict = Depends(current_user)) -> PlainTextResponse:
    rec = STORE.requests.get(request_id)
    if not rec:
        raise HTTPException(404, "not_found")
    lang = language or user.get("language") or rec.get("language") or "en"
    walk = walk_to_door(rec, language=lang)
    hi = str(lang).lower().startswith("hi")
    if hi:
        msg = (
            f"SaHayak · रक्त मदद पास\n"
            f"{rec.get('recipient_group')} · {rec.get('hospital_name')}\n"
            f"{walk}\n"
            f"यह टेक्स्ट आप खुद Status पर लगाएँ।"
        )
    else:
        msg = (
            f"SaHayak · blood help nearby\n"
            f"Need {rec.get('recipient_group')} at {rec.get('hospital_name')}\n"
            f"{walk}\n"
            f"Share this text on Status yourself."
        )
    return PlainTextResponse(msg)


@app.get("/v1/widget-actions")
def widget_actions() -> dict[str, list[str]]:
    return {"actions": ["need_blood", "i_can_donate"]}


@app.get("/v1/notices")
def notices(user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] != "owner":
        raise HTTPException(403, "owner_only")
    return {"log": STORE.notice_log}


@app.get("/v1/console/summary")
def console_summary(user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] not in ("owner", "tenant_admin"):
        raise HTTPException(403, "forbidden")
    open_r = [r for r in STORE.requests.values() if r.get("status") == "open"]
    return {
        "open_requests": len(open_r),
        "donors": len(STORE.donors),
        "camps": len(STORE.camps),
        "directory": len(STORE.directory),
        "disaster_mode": STORE.disaster_mode,
        "festival_hush": STORE.festival_hush,
        "tenant": STORE.tenants.get(user.get("tenant_id", "public")),
        "open_rows": [
            {
                "id": r["id"],
                "group": r.get("recipient_group"),
                "hospital": r.get("hospital_name"),
                "units": f"{r.get('units_accepted')}/{r.get('units_needed')}",
                "status": r.get("status"),
                "last_unit": r.get("last_unit"),
                "lat": r.get("lat"),
                "lng": r.get("lng"),
            }
            for r in STORE.requests.values()
            if RunBloodRequestSaga().maybe_escalate(_expire_if_needed(r)).get("status") == "open"
        ],
    }


@app.post("/v1/console/branding")
def branding(body: dict[str, Any], user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] not in ("owner", "tenant_admin"):
        raise HTTPException(403, "forbidden")
    tid = user.get("tenant_id", "public")
    t = STORE.tenants.setdefault(tid, {"id": tid, "name": "SaHayak", "color": "#C42B4A", "subtitle": "blood help nearby"})
    if body.get("name"):
        t["name"] = body["name"]
    if body.get("color"):
        t["color"] = body["color"]
    if body.get("subtitle"):
        t["subtitle"] = body["subtitle"]
    STORE.save()
    return {"ok": True, "tenant": t, "human": "This hospital copy now shows their name. Citizen home stays two buttons."}


@app.post("/v1/assistant/messages")
def assistant(body: dict[str, str], user: dict = Depends(current_user)) -> dict[str, Any]:
    """LangGraph crew (or same nodes if the package is missing). Forms still work if this fails."""
    lat = float(body.get("lat", 22.57))
    lng = float(body.get("lng", 88.36))
    try:
        from app.graph.build import run_crew

        out = run_crew(text=body.get("text") or "", user=user, lat=lat, lng=lng)
        out["ai_llm"] = bool(cfg["flags"].get("ai_enabled"))
        return out
    except Exception:
        text = (body.get("text") or "").upper()
        group = next((g for g in cfg["blood_groups"] if g in text), "O+")
        ranked = rank_donors(
            recipient_group=group,
            origin_lat=lat,
            origin_lng=lng,
            donors=list(STORE.donors.values()),
            radius_km=float(cfg["matching"]["radius_km_steps"][0]),
        )
        return {
            "mode": "rules_fallback",
            "parsed_group": group,
            "donors": ranked,
            "human": f"Heard {group}. Crew paused; matching still uses the same rules. Family Ring still on a real send.",
        }


@app.get("/v1/assistant/reflection")
def assistant_reflection(user: dict = Depends(current_user)) -> dict[str, Any]:
    if user["role"] != "owner":
        raise HTTPException(403, "owner_only")
    return {"log": STORE.reflection_log[-50:], "human": "Bad or skipped plans for you to improve later."}


@app.get("/v1/heatmap")
def heatmap(user: dict = Depends(current_user)) -> dict[str, Any]:
    from app.domain.calm_features import heatmap_point
    
    if user["role"] not in ("owner", "tenant_admin"):
        raise HTTPException(403, "forbidden")
    cells = {}
    fog = []
    points = []
    for r in STORE.requests.values():
        if r.get("status") not in ("open", "fulfilled"):
            continue
        lat = round(float(r.get("lat") or 0), 1)
        lng = round(float(r.get("lng") or 0), 1)
        key = f"{lat},{lng}"
        cells[key] = cells.get(key, 0) + int(r.get("units_needed") or 1)
        
        # Add detailed point for visualization
        point = heatmap_point(r)
        if point:
            points.append(point)
    
    for key, n in cells.items():
        a, b = key.split(",")
        fog.append({"lat": float(a), "lng": float(b), "n": n, "name": None, "phone": None})
    
    return {
        "cells": cells,
        "fog": fog,
        "points": points,
        "source": "tenant_requests_only",
        "human": "Gold fog only. No names. No phones. Intensity shows urgency.",
    }


@app.get("/console", response_class=HTMLResponse)
def console_page() -> str:
    p = Path(__file__).resolve().parents[2] / "frontend" / "web" / "console.html"
    return p.read_text(encoding="utf-8")


@app.get("/v1/guest/{token}")
def guest_family_link(token: str) -> dict[str, Any]:
    from app.domain.calm_features import bag_progress_visual
    
    rec = STORE.requests.get(STORE.guest_tokens.get(token, token))
    if not rec:
        raise HTTPException(404, "expired_or_missing")
    mates = same_night_mates(STORE.requests, rec)
    
    # Calculate bag progress for visual
    bag_progress = bag_progress_visual(rec)
    
    return {
        "status": rec["status"],
        "hospital_name": rec.get("hospital_name"),
        "recipient_group": rec.get("recipient_group"),
        "units_progress": f"{rec.get('units_accepted', 0)}/{rec.get('units_needed', 0)}",
        "bag_progress": bag_progress,
        "ward": rec.get("ward"),
        "phone": None,
        "lane": rec.get("lane") or "sos",
        "wait_mates": len(mates),
        "wait_mates_hint": (
            f"{len(mates)} other family here tonight — no phones on this page."
            if mates
            else "No other open family listed here tonight."
        ),
        "human": "Family status only. No phone on this link.",
        "story": "bags",
    }


_WEB = Path(__file__).resolve().parents[2] / "frontend" / "web"


def _page(name: str) -> str:
    return (_WEB / name).read_text(encoding="utf-8")


@app.get("/privacy", response_class=HTMLResponse)
def privacy_page() -> str:
    return _page("privacy.html")


@app.get("/terms", response_class=HTMLResponse)
def terms_page() -> str:
    return _page("terms.html")


@app.get("/guest/{token}", response_class=HTMLResponse)
def guest_page(token: str) -> str:
    return _page("guest.html")


@app.get("/v1/features")
def features() -> dict[str, str]:
    return {
        "family_ring": "notify trusted first",
        "give_window": "donor-push availability",
        "help_without_blood": "ride wait translate share",
        "hospital_qr": "verified ward request",
        "safety_checkin": "eta to hospital",
        "rare_watch": "rare group alerts",
        "language_bridge": "request in donor language",
        "disaster_mode": "district surge switch",
        "grace_date": "next eligible day",
        "stand_in": "family takes the call",
        "last_unit": "auto widen and banks",
        "ping_rest": "max one public ping per 24h",
        "offline_sos": "queue when offline",
        "station_window": "geofenced give-window",
        "society_ring": "opt-in building",
        "status_card": "share image no whatsapp api",
        "home_widget": "need blood / i can donate",
        "camp_passport_qr": "offline camp checkin",
        "thank_quietly": "private thanks",
        "print_poster": "console a4 qr",
        "guest_family_link": "expiring web status",
        "self_hold": "fasting fever skip pings",
        "guardian": "minor patient adult contact",
        "nss_hours": "volunteer pdf",
        "bank_to_bank": "console transfer",
        "camp_rsvp": "book camp slot",
        "hospital_slip": "fill form from paper, never send",
        "regular_lane": "monthly bag, no public ping",
        "same_night": "same hospital wait, no phones",
        "ride_window": "one local/metro ride then gone",
        "family_notebook": "private heirloom groups",
        "night_banks": "directory after 10pm",
    }


@app.get("/")
def root() -> RedirectResponse:
    return RedirectResponse("/app/")


if _WEB.is_dir():
    app.mount("/app", StaticFiles(directory=str(_WEB), html=True), name="citizen_web")
