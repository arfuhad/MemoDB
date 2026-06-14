#!/usr/bin/env python3
"""Seed the running backend with sample notes and run a few semantic queries.

Dependency-free (stdlib only). Use it to sanity-check the P1 done-bar:
"type a thing; later, a meaning-based search surfaces it without the exact words."

    python scripts/seed.py            # seed + run sample queries
    python scripts/seed.py --query "how do I remember things"

Requires the backend running and PKM_API_TOKEN matching.
"""
from __future__ import annotations

import argparse
import json
import os
import urllib.request

API = os.environ.get("PKM_API_BASE", "http://localhost:8000")
TOKEN = os.environ.get("PKM_API_TOKEN", "dev-local-token-change-me")

NOTES = [
    "Spaced repetition beats cramming because retrieval practice strengthens memory over time.",
    "The forgetting curve shows we lose most new information within days unless we review it.",
    "Compound interest means your returns earn returns; time in the market dominates timing.",
    "Index funds win long term mostly by keeping fees low and staying diversified.",
    "Sleep consolidates memory; deep sleep moves the day's learning into long-term storage.",
    "A good morning routine protects deep-focus hours from meetings and notifications.",
    "Docker images should be small: use slim bases and multi-stage builds to cut size.",
    "Postgres indexes speed reads but cost writes; index the columns you actually filter on.",
    "Vector search finds notes by meaning, not keywords, using embeddings and cosine distance.",
    "Local-first apps keep data on device so they stay fast and work offline.",
    "Walking after meals blunts blood-sugar spikes and aids digestion.",
    "Strength training preserves muscle and bone density as you age.",
    "Writing forces clarity: if you can't explain it simply, you don't understand it yet.",
    "Atomic notes hold one idea each, which makes them easier to link and reuse.",
    "Reciprocal rank fusion blends two rankings without needing comparable scores.",
    "A small cloud VM can host the backend so the app works away from home.",
    "Burnout often comes from lack of control, not just long hours.",
    "Reading widely gives you more dots to connect; depth turns dots into judgment.",
    "Cosine similarity compares direction, so vector length doesn't distort the match.",
    "Habits stick when the cue is obvious and the first action is tiny.",
]

QUERIES = [
    "how do I remember things long term",
    "saving money for retirement",
    "make my database queries faster",
    "searching notes by meaning",
]


def _req(method: str, path: str, body: dict | None = None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(f"{API}{path}", data=data, method=method)
    req.add_header("Authorization", f"Bearer {TOKEN}")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def seed() -> None:
    for note in NOTES:
        _req("POST", "/capture", {"text": note, "tags": []})
    print(f"Seeded {len(NOTES)} notes.")


def run_query(q: str) -> None:
    from urllib.parse import quote
    res = _req("GET", f"/search?q={quote(q)}&limit=3")
    print(f"\n? {q}")
    for h in res["hits"]:
        marks = ("S" if h.get("vector_rank") else "-") + ("K" if h.get("keyword_rank") else "-")
        print(f"   [{marks} {h['score']:.4f}] {h['title']}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--query", help="run a single query instead of the samples")
    ap.add_argument("--no-seed", action="store_true", help="skip seeding")
    args = ap.parse_args()

    if not args.no_seed:
        seed()
    if args.query:
        run_query(args.query)
    else:
        for q in QUERIES:
            run_query(q)
