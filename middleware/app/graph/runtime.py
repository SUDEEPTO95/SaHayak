"""Provider-neutral LLM runtime with prompts, budgets, retries, and traces."""
from __future__ import annotations

import os
import time
from collections import defaultdict
from typing import Any

from app.config_loader import load_config
from app.store import STORE

_usage: dict[str, int] = defaultdict(int)


def prompt(name: str) -> str:
    ai = load_config().get("ai", {})
    return str(ai.get("prompts", {}).get(name, "Reply with valid JSON only."))


def _budget_key() -> str:
    return time.strftime("%Y-%m-%d", time.gmtime())


def _record_trace(row: dict[str, Any]) -> None:
    STORE.ai_traces.append({"at": time.time(), **row})
    STORE.ai_traces = STORE.ai_traces[-500:]
    STORE.save()


def classify_intent(text: str) -> str | None:
    """Call an OpenAI-compatible provider only when configured and within budget."""
    ai = load_config().get("ai", {})
    if not ai.get("enabled"):
        return None
    key = os.environ.get(str(ai.get("api_key_env", "GROQ_API_KEY")))
    if not key:
        return None
    budget_key = _budget_key()
    max_calls = int(ai.get("daily_call_budget", 100))
    if _usage[budget_key] >= max_calls:
        _record_trace({"kind": "llm", "status": "budget_exhausted", "provider": ai.get("provider")})
        return None

    import httpx

    endpoint = str(ai.get("endpoint", "https://api.groq.com/openai/v1/chat/completions"))
    payload = {
        "model": os.environ.get("SAHAYAK_LLM_MODEL", str(ai.get("model", "llama-3.1-8b-instant"))),
        "messages": [
            {"role": "system", "content": prompt("intent")},
            {"role": "user", "content": (text or "")[:500]},
        ],
        "temperature": 0,
        "max_tokens": 8,
    }
    retries = max(1, min(3, int(ai.get("max_retries", 2))))
    started = time.perf_counter()
    for attempt in range(1, retries + 1):
        try:
            response = httpx.post(
                endpoint,
                headers={"Authorization": f"Bearer {key}"},
                json=payload,
                timeout=float(ai.get("timeout_seconds", 8)),
            )
            response.raise_for_status()
            word = (response.json()["choices"][0]["message"]["content"] or "").strip().lower()
            if word in {"faq", "match", "create", "refuse", "clarify"}:
                _usage[budget_key] += 1
                _record_trace({
                    "kind": "llm",
                    "status": "ok",
                    "provider": ai.get("provider"),
                    "model": payload["model"],
                    "attempt": attempt,
                    "latency_ms": round((time.perf_counter() - started) * 1000),
                })
                return word
        except Exception as exc:
            if attempt == retries:
                _record_trace({"kind": "llm", "status": "fallback", "error": type(exc).__name__})
    return None