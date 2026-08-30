"""
LangGraph crew is implemented in middleware/app/graph (behind /v1).
This file only names nodes. Do not import Flutter. Do not expose this host to phones.
"""

GRAPH_NODES = [
    "orchestrator",
    "triage_agent",
    "matcher_agent",
    "outreach_agent",
    "compliance_agent",
    "knowledge_agent",
    "ops_agent",
    "reflection_agent",
]


def assert_family_ring_before_public(steps: list[str]) -> None:
    if "notify_public_ping_rest" in steps:
        assert steps.index("notify_family_ring") < steps.index("notify_public_ping_rest")
