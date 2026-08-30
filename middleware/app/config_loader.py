"""
Load product config from repo config/sahayak.json.
File: middleware/app/config_loader.py → repo root is parents[2].
"""
from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path


def _config_path() -> Path:
    here = Path(__file__).resolve()
    return here.parents[2] / "config" / "sahayak.json"


@lru_cache
def load_config() -> dict:
    path = _config_path()
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)
