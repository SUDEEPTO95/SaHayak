"""Plain words for the family after send. Not error codes."""
from __future__ import annotations

from typing import Any


def after_send(rec: dict[str, Any], *, merged: bool, language: str = "en") -> str:
    hi = (language or "en").lower().startswith("hi")
    if merged:
        if hi:
            return "यही आपात पहले से खुली है। दूसरी पोस्ट नहीं बनाई। फोन अभी छिपा है।"
        return "This looks like the same emergency. We did not double-ping. Phones stay hidden."


def walk_to_door(rec: dict[str, Any], *, language: str = "en") -> str:
    hi = (language or "en").lower().startswith("hi")
    hosp = rec.get("hospital_name") or "the hospital"
    ward = rec.get("ward") or "—"
    if hi:
        return f"{hosp} · वार्ड {ward} · ब्लड बैंक का दरवाज़ा — बिस्तर पर नहीं। फोन स्वीकार के बाद ही।"
    return f"{hosp} · ward {ward} · blood bank door — not the bedside. Phone only after you accepted."
    if rec.get("lane") == "regular":
        if hi:
            return "मासिक थैली: सिर्फ़ Family Ring और सूचीबद्ध बैंक। सार्वजनिक पिंग नहीं। परिवार वाला लिंक — फोन नहीं।"
        return "Monthly bag: Family Ring and listed banks only. No public ping. Share the family link — no phone on that page."
    wait = int(rec.get("escalate_wait_minutes") or 15)
    fam = len(rec.get("family_ring_notified") or [])
    n = len(rec.get("matched_donor_ids") or [])
    if hi:
        return (
            f"Family Ring को पहले बताया ({fam} लोग)। पास में {n} मैचिंग नाम, फोन छिपा। "
            f"{wait} मिनट में कोई स्वीकार न करे तो सूचीबद्ध अस्पताल/बैंक को बताएँगे। "
            "परिवार वाला लिंक — उस पेज पर फोन नहीं।"
        )
    return (
        f"We told your Family Ring first ({fam} people). {n} compatible nearby — phones hidden. "
        f"If nobody accepts in {wait} minutes, we tell listed hospitals and banks. "
        "Share the family link. It never shows a phone."
    )
