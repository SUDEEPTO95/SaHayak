"""Tiny keyword RAG until Postgres pgvector. Same chunks KnowledgeAgent reads."""
from __future__ import annotations

from pathlib import Path

_DOC = Path(__file__).resolve().parents[2] / "data" / "knowledge" / "eligibility_first_aid.md"


def retrieve(query: str, limit: int = 3) -> list[str]:
    text = _DOC.read_text(encoding="utf-8") if _DOC.exists() else ""
    parts = [p.strip() for p in text.split("#") if p.strip()]
    q = {w.lower() for w in query.replace("/", " ").split() if len(w) > 2}
    scored: list[tuple[int, str]] = []
    for p in parts:
        words = {w.lower() for w in p.split() if len(w) > 2}
        scored.append((len(q & words), p[:500]))
    scored.sort(reverse=True)
    hits = [s[1] for s in scored if s[0] > 0][:limit]
    if not hits and parts:
        hits = [parts[0][:500]]
    return hits
