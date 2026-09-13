"""Safety and quality checks around graph execution."""
from __future__ import annotations

from typing import Any


EXPECTED_ORDER = {
    "orchestrator": 0,
    "triage_agent": 1,
    "matcher_agent": 2,
    "outreach_agent": 3,
    "knowledge_agent": 1,
    "ops_agent": 1,
    "compliance_agent": 4,
    "reflection_agent": 5,
}


def validate_output(state: dict[str, Any]) -> dict[str, Any]:
    """Sanitize unsafe output and record deterministic graph contract checks."""
    donors = []
    for donor in state.get("donors") or []:
        safe = dict(donor)
        safe.pop("phone", None)
        donors.append(safe)
    plan = list(state.get("plan") or [])
    positions = [EXPECTED_ORDER.get(step, 99) for step in plan]
    ordered = positions == sorted(positions)
    compliance = dict(state.get("compliance") or {})
    compliance.update({"phones_hidden": True, "plan_order_valid": ordered})
    return {**state, "donors": donors, "compliance": compliance, "harness": {"ok": ordered}}