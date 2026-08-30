"""LangGraph crew. Flutter never imports this. Same tools if the library is missing."""
from __future__ import annotations

from typing import Any, Callable

from app.graph.nodes import (
    compliance,
    knowledge,
    matcher,
    orchestrator,
    ops,
    outreach,
    reflection,
    triage,
)


def _route_after_orchestrator(state: dict[str, Any]) -> str:
    intent = state.get("intent")
    if intent == "faq":
        return "knowledge"
    if intent == "ops":
        return "ops"
    if intent == "refuse":
        return "compliance"
    return "triage"


def _route_after_triage(state: dict[str, Any]) -> str:
    if state.get("question") and not (state.get("parsed") or {}).get("recipient_group"):
        return "compliance"
    return "matcher"


def _compile_langgraph() -> Any | None:
    try:
        from langgraph.graph import END, START, StateGraph
    except ImportError:
        return None

    g: Any = StateGraph(dict)
    g.add_node("orchestrator", orchestrator)
    g.add_node("triage", triage)
    g.add_node("matcher", matcher)
    g.add_node("outreach", outreach)
    g.add_node("knowledge", knowledge)
    g.add_node("ops", ops)
    g.add_node("compliance", compliance)
    g.add_node("reflection", reflection)
    g.add_edge(START, "orchestrator")
    g.add_conditional_edges(
        "orchestrator",
        _route_after_orchestrator,
        {
            "knowledge": "knowledge",
            "ops": "ops",
            "compliance": "compliance",
            "triage": "triage",
        },
    )
    g.add_conditional_edges(
        "triage",
        _route_after_triage,
        {"compliance": "compliance", "matcher": "matcher"},
    )
    g.add_edge("matcher", "outreach")
    g.add_edge("outreach", "compliance")
    g.add_edge("knowledge", "compliance")
    g.add_edge("ops", "compliance")
    g.add_edge("compliance", "reflection")
    g.add_edge("reflection", END)
    return g.compile()


_COMPILED = None


def _fallback_invoke(state: dict[str, Any]) -> dict[str, Any]:
    """Same node functions, same order, if LangGraph is not installed."""
    state = orchestrator(state)
    nxt = _route_after_orchestrator(state)
    chain: dict[str, Callable[[dict[str, Any]], dict[str, Any]]] = {
        "knowledge": knowledge,
        "ops": ops,
        "triage": triage,
        "compliance": compliance,
    }
    state = chain[nxt](state)
    if nxt == "triage":
        nxt2 = _route_after_triage(state)
        if nxt2 == "matcher":
            state = matcher(state)
            state = outreach(state)
        state = compliance(state)
    elif nxt in {"knowledge", "ops"}:
        state = compliance(state)
    state = reflection(state)
    return state


def run_crew(*, text: str, user: dict[str, Any], lat: float, lng: float) -> dict[str, Any]:
    global _COMPILED
    start = {
        "text": text,
        "user": {k: v for k, v in user.items() if k != "token"},
        "role": user.get("role"),
        "lat": lat,
        "lng": lng,
        "plan": [],
    }
    engine = "langgraph"
    try:
        if _COMPILED is None:
            _COMPILED = _compile_langgraph()
        if _COMPILED is not None:
            out = _COMPILED.invoke(start)
        else:
            engine = "nodes_without_langgraph_pkg"
            out = _fallback_invoke(start)
    except Exception as exc:
        engine = f"fallback:{type(exc).__name__}"
        out = _fallback_invoke(start)
    return {
        "mode": engine,
        "intent": out.get("intent"),
        "parsed": out.get("parsed"),
        "donors": out.get("donors") or [],
        "outreach": out.get("outreach"),
        "knowledge": out.get("knowledge"),
        "ops": out.get("ops"),
        "compliance": out.get("compliance"),
        "question": out.get("question") or "",
        "plan": out.get("plan"),
        "human": out.get("human")
        or "Same matching rules. Family Ring still runs when you send a real request.",
        "note": "Need blood on home does not wait for this crew. If this path fails, forms still work.",
    }
