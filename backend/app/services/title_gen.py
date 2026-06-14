"""LLM-based title suggestion via Ollama generate API.

Falls back to the first-line heuristic if the model is unavailable or
not configured, so the endpoint always returns something useful.
"""
from __future__ import annotations

import re

import httpx

_PROMPT = (
    "Write a short title (max 8 words) for the note below. "
    "Reply with only the title — no quotes, no punctuation at the end, "
    "no explanation.\n\nNote:\n{snippet}\n\nTitle:"
)


class TitleGenerator:
    def __init__(self, provider: str, model: str, base_url: str, api_key: str = ""):
        self.provider = provider
        self.model = model
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key

    async def suggest(self, text: str) -> str:
        if not self.model:
            return _fallback(text)
        snippet = text.strip()[:600]
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                if self.provider == "api":
                    headers = {}
                    if self.api_key:
                        headers["Authorization"] = f"Bearer {self.api_key}"
                        
                    resp = await client.post(
                        self.base_url,
                        headers=headers,
                        json={
                            "model": self.model,
                            "messages": [{"role": "user", "content": _PROMPT.format(snippet=snippet)}],
                            "temperature": 0.3,
                            "max_tokens": 32,
                        },
                    )
                    resp.raise_for_status()
                    raw = resp.json()["choices"][0]["message"]["content"].strip()
                else:
                    resp = await client.post(
                        f"{self.base_url}/api/generate",
                        json={
                            "model": self.model,
                            "prompt": _PROMPT.format(snippet=snippet),
                            "stream": False,
                            "options": {"temperature": 0.3, "num_predict": 32},
                        },
                    )
                    resp.raise_for_status()
                    raw = resp.json().get("response", "").strip()
        except Exception as e:
            print(f"TitleGen error: {e}")
            return _fallback(text)

        title = _clean(raw)
        return title[:100] if title else _fallback(text)


def _clean(raw: str) -> str:
    title = raw.strip().strip("\"'").strip()
    # Strip echoed "Title:" prefix some models add
    title = re.sub(r"(?i)^title\s*:\s*", "", title).strip()
    # Collapse newlines — take only the first line
    title = title.splitlines()[0].strip() if title else ""
    # Strip trailing sentence punctuation
    return title.rstrip(".!?")


def _fallback(text: str) -> str:
    first = text.strip().splitlines()[0] if text.strip() else "Untitled"
    return first[:80].strip() or "Untitled"
