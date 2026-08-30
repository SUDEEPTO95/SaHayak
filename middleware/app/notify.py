"""Notice port. FCM/WhatsApp stay off until flags are on; always keep an audit log."""
from __future__ import annotations

from typing import Any

from app.config_loader import load_config
from app.store import STORE


def notify(channel: str, target_id: str, request_id: str, body: str) -> dict[str, Any]:
    cfg = load_config()["flags"]
    row = {
        "channel": channel,
        "target_id": str(target_id),
        "request_id": request_id,
        "body": body,
        "fcm_would_send": bool(cfg.get("fcm_enabled")),
        "whatsapp_would_send": bool(cfg.get("whatsapp_enabled")),
    }
    STORE.notice_log.append(row)
    STORE.save()
    return row
