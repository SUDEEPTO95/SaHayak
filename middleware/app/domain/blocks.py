"""One pause card for the family. Same words on web, app, and PHP proxy."""
from __future__ import annotations

from typing import Any

BLOCKS: dict[str, dict[str, str]] = {
    "no_internet": {
        "title": "The line is quiet",
        "line": "This phone has no internet right now. You stay on this page. Nothing was sent.",
        "ok": "OK",
    },
    "location_denied": {
        "title": "Location stayed off",
        "line": "SaHayak did not get location. Pick a city instead. You stay here.",
        "ok": "OK",
    },
    "location_off": {
        "title": "Location is not available",
        "line": "Use the city list. We never follow you in the background.",
        "ok": "OK",
    },
    "server_quiet": {
        "title": "SaHayak could not answer",
        "line": "The helping-hand line is not reaching this computer. You stay on this page. Try OK, then the same button again.",
        "ok": "OK",
    },
    "session_ended": {
        "title": "Please sign in again when you are ready",
        "line": "This session ended. You are still on this page. Nothing was posted.",
        "ok": "OK",
    },
    "account_paused": {
        "title": "This account is paused",
        "line": "Write to the owner. You stay here. We did not move you away.",
        "ok": "OK",
    },
    "too_many": {
        "title": "A short pause",
        "line": "Too many tries just now. Stay here. Wait a moment, then OK.",
        "ok": "OK",
    },
    "generic": {
        "title": "A small pause",
        "line": "Something needed a moment. You stay on this page. Nothing extra was sent.",
        "ok": "OK",
    },
}

ERROR_TO_BLOCK = {
    "missing_token": "session_ended",
    "invalid_token": "session_ended",
    "account_frozen": "account_paused",
    "otp_rate": "too_many",
    "seeker_throttle": "too_many",
    "python_middleware_unreachable": "server_quiet",
}


def block_for(error: str | None, *, status: int = 400, language: str = "en") -> dict[str, Any]:
    code = ERROR_TO_BLOCK.get(str(error or ""), "")
    if not code:
        if status == 401:
            code = "session_ended"
        elif status == 403:
            code = "account_paused"
        elif status == 429:
            code = "too_many"
        elif status >= 500:
            code = "server_quiet"
        else:
            code = "generic"
    row = dict(BLOCKS.get(code) or BLOCKS["generic"])
    hi = (language or "en").lower().startswith("hi")
    if hi:
        row = _hi(code, row)
    return {"code": code, "title": row["title"], "line": row["line"], "ok": row["ok"], "stay": True}


def _hi(code: str, row: dict[str, str]) -> dict[str, str]:
    table = {
        "no_internet": ("लाइन शांत है", "अभी इंटरनेट नहीं। आप इसी पेज पर हैं। कुछ नहीं भेजा गया।", "ठीक"),
        "location_denied": ("लोकेशन बंद रही", "शहर चुनें। आप यहीं रहेंगे।", "ठीक"),
        "location_off": ("लोकेशन नहीं मिली", "शहर की सूची इस्तेमाल करें। पीछे से नहीं।", "ठीक"),
        "server_quiet": ("SaHayak जवाब नहीं दे सका", "आप इसी पेज पर हैं। OK दबाएँ, फिर वही बटन।", "ठीक"),
        "session_ended": ("जब तैयार हों, फिर दाखिल हों", "सेशन खत्म। आप यहीं हैं। कुछ पोस्ट नहीं हुआ।", "ठीक"),
        "account_paused": ("यह खाता रुका है", "मालिक को लिखें। हमने पेज नहीं बदला।", "ठीक"),
        "too_many": ("थोड़ा रुकें", "अभी बहुत कोशिशें। यहीं रहें।", "ठीक"),
        "generic": ("एक छोटी रोक", "आप इसी पेज पर हैं। कुछ और नहीं भेजा।", "ठीक"),
    }
    if code in table:
        t, line, ok = table[code]
        return {"title": t, "line": line, "ok": ok}
    return row
