"""Specialist nodes. LLM is optional; rules always work so SOS forms stay independent."""
from __future__ import annotations

import os
import re
from typing import Any

from app.config_loader import load_config
from app.graph.tools import (
    knowledge_search,
    ops_snapshot,
    search_donors,
    strip_phones,
    who_to_notify,
)
from app.store import STORE

HOSPITALS = (
    "SSKM",
    "HOWRAH",
    "AIIMS",
    "CMC",
    "NIMHANS",
    "TATA",
    "NRS",
    "RG KAR",
    "RGKAR",
    "MEDICAL COLLEGE",
    "CMRI",
    "APOLLO",
    "FORTIS",
)


def _groups() -> list[str]:
    return list(load_config()["blood_groups"])


def parse_group(text: str) -> str | None:
    up = text.upper().replace("POSITIVE", "+").replace("NEGATIVE", "-").replace(" ", "")
    for g in sorted(_groups(), key=len, reverse=True):
        if g.replace("+", "P") in up.replace("+", "P") or g in up:
            return g
        compact = g.replace("+", "").replace("-", "")
        if compact + "POSITIVE" in text.upper().replace(" ", ""):
            return g
    if "B+" in up or "BPOSITIVE" in text.upper().replace(" ", ""):
        return "B+"
    return None


def parse_hospital(text: str) -> str:
    up = text.upper()
    for h in sorted(HOSPITALS, key=len, reverse=True):
        if h in up:
            if h == "SSKM":
                return "SSKM"
            if h in ("RG KAR", "RGKAR"):
                return "RG Kar"
            return h.title()
    m = re.search(r"(?:at|@)\s+([A-Za-z][A-Za-z0-9 .]{1,40})", text, re.I)
    return (m.group(1).strip() if m else "")[:40]


def parse_need_message(text: str) -> dict[str, Any]:
    """Fill a Need blood form. Never creates a request by itself."""
    low = text.lower()
    units = 2
    um = re.search(r"(\d+)\s*(unit|units|bag|bags)", text, re.I)
    if um:
        units = max(1, min(20, int(um.group(1))))
    ward = ""
    wm = re.search(r"ward\s*[:\-]?\s*([A-Za-z0-9]+)", text, re.I)
    if wm:
        ward = wm.group(1)
    bed = ""
    bm = re.search(r"bed\s*[:\-]?\s*([A-Za-z0-9]+)", text, re.I)
    if bm:
        bed = bm.group(1)
    return {
        "recipient_group": parse_group(text),
        "hospital_name": parse_hospital(text),
        "ward": ward,
        "bed": bed,
        "units": units,
        "urgency": "critical" if any(w in low for w in ("now", "tonight", "emergency", "abhi", "jaldi")) else "scheduled",
        "component": "plasma" if "plasma" in low else ("platelets" if "platelet" in low else "whole"),
    }


def maybe_llm_intent(text: str) -> str | None:
    """Only if a key is present. Never required. Never talks to SQL."""
    if not load_config()["flags"].get("ai_enabled"):
        return None
    key = os.environ.get("SAHAYAK_GROQ_KEY") or os.environ.get("GROQ_API_KEY")
    if not key:
        return None
    try:
        import httpx

        r = httpx.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={"Authorization": f"Bearer {key}"},
            json={
                "model": os.environ.get("SAHAYAK_GROQ_MODEL", "llama-3.1-8b-instant"),
                "messages": [
                    {
                        "role": "system",
                        "content": "Reply with one word only: faq, match, create, refuse, or clarify.",
                    },
                    {"role": "user", "content": text[:500]},
                ],
                "temperature": 0,
                "max_tokens": 8,
            },
            timeout=8.0,
        )
        word = (r.json()["choices"][0]["message"]["content"] or "").strip().lower()
        if word in {"faq", "match", "create", "refuse", "clarify"}:
            return word
    except Exception:
        return None
    return None


def orchestrator(state: dict[str, Any]) -> dict[str, Any]:
    text = state.get("text") or ""
    low = text.lower()
    llm = maybe_llm_intent(text)
    if llm:
        intent = llm
    elif any(w in low for w in ("fever", "fasting", "eligible", "eligibility", "bleed", "burn", "first aid", "first-aid")):
        intent = "faq"
    elif any(w in low for w in ("stock", "stale", "heatmap", "camp", "console")) and state.get("role") in (
        "owner",
        "tenant_admin",
    ):
        intent = "ops"
    elif any(w in low for w in ("diagnose", "what disease", "prescribe")):
        intent = "refuse"
    elif parse_group(text) and parse_hospital(text) and any(w in low for w in ("need", "send", "request", "emergency", "unit")):
        intent = "create"
    elif parse_group(text) or "donor" in low or "nearby" in low or "match" in low:
        intent = "match"
    elif len(text.strip()) < 4:
        intent = "clarify"
    else:
        intent = "clarify"
    return {**state, "intent": intent, "plan": ["orchestrator"]}


def triage(state: dict[str, Any]) -> dict[str, Any]:
    text = state.get("text") or ""
    parsed = parse_need_message(text)
    question = ""
    if state.get("intent") == "clarify" or not parsed.get("recipient_group"):
        question = "Which blood group did the hospital write? Example: B+ at SSKM."
        if parsed.get("recipient_group") and not parsed.get("hospital_name"):
            question = "Which hospital? Example: SSKM."
    plan = list(state.get("plan") or []) + ["triage_agent"]
    return {**state, "parsed": parsed, "question": question, "plan": plan}


def matcher(state: dict[str, Any]) -> dict[str, Any]:
    parsed = state.get("parsed") or {}
    group = parsed.get("recipient_group") or "O+"
    donors = search_donors(
        recipient_group=group,
        lat=float(state.get("lat") or 22.57),
        lng=float(state.get("lng") or 88.36),
    )
    plan = list(state.get("plan") or []) + ["matcher_agent"]
    return {**state, "donors": donors, "plan": plan}


def outreach(state: dict[str, Any]) -> dict[str, Any]:
    user_id = (state.get("user") or {}).get("id") or ""
    donors = state.get("donors") or []
    order = who_to_notify(user_id, [d.get("id") for d in donors if d.get("id")])
    plan = list(state.get("plan") or []) + ["outreach_agent"]
    note = "Family Ring first. This lookup does not skip them. A real Need blood tap still runs the full saga."
    return {**state, "outreach": order, "outreach_note": note, "plan": plan}


def knowledge(state: dict[str, Any]) -> dict[str, Any]:
    hits = knowledge_search(state.get("text") or "")
    plan = list(state.get("plan") or []) + ["knowledge_agent"]
    return {**state, "knowledge": hits, "plan": plan}


def ops(state: dict[str, Any]) -> dict[str, Any]:
    snap = ops_snapshot((state.get("user") or {}).get("role") or "user")
    plan = list(state.get("plan") or []) + ["ops_agent"]
    return {**state, "ops": snap, "plan": plan}


def compliance(state: dict[str, Any]) -> dict[str, Any]:
    donors = strip_phones(list(state.get("donors") or []))
    refuse = state.get("intent") == "refuse"
    human = _human(state)
    if refuse:
        human = "SaHayak cannot diagnose or prescribe. Please speak to a doctor. Need blood is still on the home screen."
    plan = list(state.get("plan") or []) + ["compliance_agent"]
    return {
        **state,
        "donors": donors,
        "compliance": {
            "phones_hidden": True,
            "no_diagnosis": True,
            "tenant_id": (state.get("user") or {}).get("tenant_id"),
            "family_ring_not_skipped": True,
        },
        "human": human,
        "plan": plan,
    }


def reflection(state: dict[str, Any]) -> dict[str, Any]:
    row = {
        "plan": state.get("plan"),
        "intent": state.get("intent"),
        "question": state.get("question"),
        "ok": state.get("intent") != "refuse",
    }
    STORE.reflection_log.append(row)
    STORE.save()
    plan = list(state.get("plan") or []) + ["reflection_agent"]
    return {**state, "plan": plan, "reflected": True}


def _human(state: dict[str, Any]) -> str:
    intent = state.get("intent")
    parsed = state.get("parsed") or {}
    q = state.get("question") or ""
    if q and intent in {"clarify", "create", "match"} and not parsed.get("recipient_group"):
        return q
    if intent == "faq":
        bits = state.get("knowledge") or []
        return (bits[0] if bits else "Informational only, not medical advice.") + " This is not a doctor."
    if intent == "ops":
        ops = state.get("ops") or {}
        if not ops.get("allowed"):
            return "Console hints are for hospital staff, not the two home buttons."
        return f"Open {ops.get('open_requests', 0)}. Stale {len(ops.get('stale_open_ids') or [])}. Not a live stock system."
    group = parsed.get("recipient_group") or "that group"
    n = len(state.get("donors") or [])
    fam = len((state.get("outreach") or {}).get("family_ring") or [])
    extra = q if (intent == "create" and not parsed.get("hospital_name")) else ""
    return (
        f"Heard {group}. {n} compatible nearby (phones hidden). "
        f"Family Ring ({fam}) is first on a real send. {extra}"
    ).strip()
