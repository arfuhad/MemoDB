"""Indexer — keeps Postgres in sync with the vault.

Invariant: the vault file is written FIRST (by the vault service); the indexer
then upserts the derived rows. The index is fully reconstructable via rebuild().
Only changed chunks are re-embedded (text_hash diff)."""
from __future__ import annotations

import json

import asyncpg

from ..config import LOCAL_USER_ID
from ..db import to_pgvector
from .chunker import chunk_text
from .embeddings.base import Embedder
from .vault import Vault, VaultDocument


class Indexer:
    def __init__(self, pool: asyncpg.Pool, vault: Vault, embedder: Embedder):
        self.pool = pool
        self.vault = vault
        self.embedder = embedder

    async def index_document(self, doc: VaultDocument) -> int:
        """Upsert a single document and its chunks. Returns chunks embedded."""
        async with self.pool.acquire() as conn:
            async with conn.transaction():
                await conn.execute(
                    """
                    INSERT INTO documents
                        (id, user_id, vault_path, kind, title, body_text,
                         frontmatter, content_hash, created_at, updated_at)
                    VALUES ($1,$2,$3,$4,$5,$6,$7::jsonb,$8,$9,$10)
                    ON CONFLICT (id) DO UPDATE SET
                        vault_path=EXCLUDED.vault_path,
                        title=EXCLUDED.title,
                        body_text=EXCLUDED.body_text,
                        frontmatter=EXCLUDED.frontmatter,
                        content_hash=EXCLUDED.content_hash,
                        updated_at=EXCLUDED.updated_at
                    """,
                    doc.id, LOCAL_USER_ID, doc.vault_path, doc.kind, doc.title,
                    doc.body, json.dumps(doc.frontmatter), doc.content_hash,
                    doc.created_at, doc.updated_at,
                )

                chunks = chunk_text(doc.body)
                existing = {
                    r["ord"]: r["text_hash"]
                    for r in await conn.fetch(
                        "SELECT ord, text_hash FROM chunks WHERE document_id=$1",
                        doc.id,
                    )
                }
                # Drop chunks that no longer exist (document shrank).
                await conn.execute(
                    "DELETE FROM chunks WHERE document_id=$1 AND ord >= $2",
                    doc.id, len(chunks),
                )

                to_embed = [c for c in chunks if existing.get(c.ord) != c.text_hash]
                vectors = await self.embedder.embed([c.text for c in to_embed]) if to_embed else []

                for chunk, vector in zip(to_embed, vectors):
                    await conn.execute(
                        """
                        INSERT INTO chunks
                            (user_id, document_id, ord, text, text_hash,
                             embedding, embedding_model, embedded_at)
                        VALUES ($1,$2,$3,$4,$5,$6::vector,$7, now())
                        ON CONFLICT (document_id, ord) DO UPDATE SET
                            text=EXCLUDED.text,
                            text_hash=EXCLUDED.text_hash,
                            embedding=EXCLUDED.embedding,
                            embedding_model=EXCLUDED.embedding_model,
                            embedded_at=now()
                        """,
                        LOCAL_USER_ID, doc.id, chunk.ord, chunk.text,
                        chunk.text_hash, to_pgvector(vector), self.embedder.model,
                    )
                return len(to_embed)

    async def rebuild(self) -> tuple[int, int]:
        """Reconstruct the entire index from the vault. Proof the DB is disposable."""
        async with self.pool.acquire() as conn:
            await conn.execute("TRUNCATE chunks, documents RESTART IDENTITY CASCADE")
        docs = 0
        embedded = 0
        for doc in self.vault.scan():
            embedded += await self.index_document(doc)
            docs += 1
        return docs, embedded
