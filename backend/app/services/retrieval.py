"""Hybrid retrieval: vector similarity (cosine, HNSW) fused with Postgres FTS via
Reciprocal Rank Fusion. Semantic is the primary signal; keyword fusion is a cheap
accuracy boost. Returns one hit per document (best matching chunk)."""
from __future__ import annotations

import asyncpg

from ..config import LOCAL_USER_ID
from ..db import to_pgvector
from .chunker import make_snippet
from .embeddings.base import Embedder

RRF_K = 60  # standard reciprocal-rank-fusion damping constant


def _rrf(rank: int) -> float:
    return 1.0 / (RRF_K + rank)


async def search(pool: asyncpg.Pool, embedder: Embedder, query: str,
                 limit: int = 10, candidate_k: int = 50) -> list[dict]:
    query = query.strip()
    if not query:
        return []

    qvec = to_pgvector(await embedder.embed_one(query))

    async with pool.acquire() as conn:
        # Vector candidates: nearest chunks by cosine distance (uses HNSW index).
        # Fetch extra rows so de-duplication to best-chunk-per-document still
        # yields up to candidate_k distinct documents.
        chunk_rows = await conn.fetch(
            """
            SELECT c.document_id, d.title, c.text,
                   c.embedding <=> $1::vector AS distance
            FROM chunks c
            JOIN documents d ON d.id = c.document_id
            WHERE c.user_id = $2 AND c.embedding IS NOT NULL
            ORDER BY c.embedding <=> $1::vector
            LIMIT $3
            """,
            qvec, LOCAL_USER_ID, candidate_k * 3,
        )
        # Keep the best (nearest) chunk per document, preserving distance order.
        seen: set[str] = set()
        vector_ranked = []
        for row in chunk_rows:
            doc_id = str(row["document_id"])
            if doc_id in seen:
                continue
            seen.add(doc_id)
            vector_ranked.append(row)
            if len(vector_ranked) >= candidate_k:
                break

        # Keyword candidates: FTS over document body/title.
        keyword_rows = await conn.fetch(
            """
            SELECT d.id AS document_id, d.title, d.body_text AS text,
                   ts_rank(d.fts, websearch_to_tsquery('english', $1)) AS rank
            FROM documents d
            WHERE d.user_id = $2
              AND d.fts @@ websearch_to_tsquery('english', $1)
            ORDER BY rank DESC
            LIMIT $3
            """,
            query, LOCAL_USER_ID, candidate_k,
        )

    fused: dict[str, dict] = {}
    for i, row in enumerate(vector_ranked):
        doc_id = str(row["document_id"])
        fused[doc_id] = {
            "document_id": doc_id, "title": row["title"], "text": row["text"],
            "score": _rrf(i), "vector_rank": i + 1, "keyword_rank": None,
        }
    for i, row in enumerate(keyword_rows):
        doc_id = str(row["document_id"])
        if doc_id in fused:
            fused[doc_id]["score"] += _rrf(i)
            fused[doc_id]["keyword_rank"] = i + 1
        else:
            fused[doc_id] = {
                "document_id": doc_id, "title": row["title"], "text": row["text"],
                "score": _rrf(i), "vector_rank": None, "keyword_rank": i + 1,
            }

    ranked = sorted(fused.values(), key=lambda h: h["score"], reverse=True)[:limit]
    for h in ranked:
        h["snippet"] = make_snippet(h.pop("text"), query)
    return ranked
