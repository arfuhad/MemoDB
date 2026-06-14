# ADR-0001 — PKM P1 Architecture

Status: Accepted · Date: 2026-06-13

## Context

A personal knowledge management system. The long-term vision ingests everything
(text, voice, images, video links), processes it, and makes it retrievable by
*meaning* using vector embeddings. P1 proves the core bet on the smallest scope.

## The P1 bet

> Retrieve-by-meaning over my own text is useful enough that I come back to it.

P1 is **text-only**. Voice / image / video, tasks, links, triage, and daily notes
are explicitly **out of P1** — they belong to a later phase and are only built if
the P1 bet holds.

## Decisions

1. **Source of truth = files on disk (hybrid).** Text artifacts are stored as
   markdown files with YAML frontmatter, server-side. Postgres + pgvector is a
   **derived, rebuildable index** (metadata, extracted text, embeddings). Drop the
   DB and `rebuild` reconstructs it from the files. The DB is never authoritative,
   so it is never the thing we sync or merge — this sidesteps offline-merge in P1.

2. **Backend API in front of the database.** Clients never hold DB credentials and
   never touch Postgres directly (security boundary). The backend owns all business
   logic, auth, the vault, embeddings, and the DB. Stack: **FastAPI (Python)** —
   chosen because the forward roadmap (embeddings, Whisper, CLIP, vector ops) is
   Python-native.

3. **Clients = Flutter, desktop + mobile, both in P1.** Thin clients that speak
   HTTPS + a bearer token. Because mobile cannot host a DB or an embedding model,
   the backend must be network-reachable: in P1 it runs on the Mac (desktop →
   localhost, phone → the Mac's LAN IP). A small cloud host for always-on /
   off-network mobile is a P2 option, not a P1 dependency (containerized, so it's
   a config change).

4. **Embeddings: local now, API fallback.** Default `nomic-embed-text` via Ollama
   (768-dim, private, no per-item cost). An `ApiEmbedder` (OpenAI/Voyage with
   `dimensions=768`) sits behind the same interface for swap-in. Embedding
   dimension is pinned at **768**; `embedding_model` is stored so a model change is
   detected and triggers a re-embed rather than silent corruption.

5. **Retrieval is hybrid.** Vector similarity (cosine, HNSW) fused with Postgres
   FTS via reciprocal-rank fusion. Semantic is the bet; FTS fusion is nearly free
   and measurably better, so it ships as support, not a separate feature.

## Invariant

**File first, index second.** Every write persists the markdown file before
touching Postgres. The index is always reconstructable from the vault.

## Architecture

```
Flutter clients (desktop + mobile) ── thin, no DB creds
        │  HTTPS / REST + JSON, bearer token
        ▼
FastAPI backend ── auth + all business logic
   ├─ Vault IO        (markdown files = source of truth)
   ├─ Indexer + chunker
   ├─ EmbeddingService (Ollama local │ API fallback)
   └─ Postgres + pgvector   ← private, never exposed
```

## Out of scope for P1 (revisit only if the bet holds)

Voice/image/video ingestion · tasks-in-notes · bidirectional links · PARA triage ·
daily notes · cross-device sync · real auth (P1 uses a static bearer token).

## Done-bar

Type a thing; later, a meaning-based search surfaces it without remembering the
words — backed by markdown openable in any editor. Rebuild-from-files parity test
passes (proving the index is disposable).
