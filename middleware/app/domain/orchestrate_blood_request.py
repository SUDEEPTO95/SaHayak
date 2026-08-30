"""Locked saga. LangGraph in backend/ai must use the same step names."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Literal

Urgency = Literal["critical", "scheduled"]

SAGA_STEPS = (
    "merge_twins",
    "notify_family_ring",
    "notify_society_ring",
    "match_nearest_compatible",
    "notify_public_ping_rest",
    "wait_or_last_unit",
    "first_accept_lock",
    "units_progress",
    "thank_quietly",
)


@dataclass
class OrchestrationState:
    request_id: str
    step: str
    log: list[str] = field(default_factory=list)


def next_step(current: str | None) -> str | None:
    if current is None:
        return SAGA_STEPS[0]
    try:
        i = SAGA_STEPS.index(current)
    except ValueError:
        return None
    if i + 1 >= len(SAGA_STEPS):
        return None
    return SAGA_STEPS[i + 1]


def escalate_wait_minutes(urgency: Urgency, cfg: dict[str, Any]) -> int:
    m = cfg["matching"]
    if urgency == "critical":
        return int(m["wait_before_escalate_minutes_critical"])
    return int(m["wait_before_escalate_minutes_scheduled"])


class OrchestrateBloodRequest:
    def __init__(self, cfg: dict[str, Any]) -> None:
        self._cfg = cfg

    def start(self, request_id: str) -> OrchestrationState:
        state = OrchestrationState(request_id=request_id, step=SAGA_STEPS[0])
        state.log.append("merge_twins")
        return state

    def advance(self, state: OrchestrationState) -> OrchestrationState:
        nxt = next_step(state.step)
        if nxt is None:
            return state
        state.step = nxt
        state.log.append(nxt)
        return state
