"""ABO compatibility from config, not per-blood-group map screens."""
from __future__ import annotations

from app.config_loader import load_config


def donors_for_recipient(recipient_group: str) -> list[str]:
    cfg = load_config()
    table = cfg["compatibility_recipient_to_donors"]
    return list(table.get(recipient_group, []))


def is_compatible(recipient_group: str, donor_group: str) -> bool:
    return donor_group in donors_for_recipient(recipient_group)
