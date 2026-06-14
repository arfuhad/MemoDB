"""Chunking for embedding granularity.

P1 uses a simple, deterministic, dependency-free splitter: paragraph-aware,
word-budgeted, with a small overlap. ~512 tokens is approximated as ~380 words
(rough 1.35 tokens/word). Short notes become a single chunk. Deterministic output
matters because `text_hash` drives "only re-embed what changed".
"""
from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass

WORDS_PER_CHUNK = 380
OVERLAP_WORDS = 40


@dataclass
class Chunk:
    ord: int
    text: str

    @property
    def text_hash(self) -> str:
        return hashlib.sha256(self.text.encode("utf-8")).hexdigest()


def _split_words(text: str) -> list[str]:
    return text.split()


def chunk_text(text: str,
               words_per_chunk: int = WORDS_PER_CHUNK,
               overlap: int = OVERLAP_WORDS) -> list[Chunk]:
    text = text.strip()
    if not text:
        return []

    words = _split_words(text)
    if len(words) <= words_per_chunk:
        return [Chunk(ord=0, text=text)]

    chunks: list[Chunk] = []
    start = 0
    ordinal = 0
    step = max(1, words_per_chunk - overlap)
    while start < len(words):
        window = words[start:start + words_per_chunk]
        chunks.append(Chunk(ord=ordinal, text=" ".join(window)))
        ordinal += 1
        if start + words_per_chunk >= len(words):
            break
        start += step
    return chunks


def make_snippet(text: str, query: str | None = None, width: int = 240) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    if not query:
        return text[:width]
    idx = text.lower().find(query.lower().split()[0]) if query.split() else -1
    if idx == -1:
        return text[:width]
    start = max(0, idx - width // 3)
    return ("…" if start > 0 else "") + text[start:start + width]
