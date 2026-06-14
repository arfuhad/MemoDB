# Architecture (summary)

> The authoritative architecture decision record is
> [`../docs/ADR-0001-architecture.md`](../docs/ADR-0001-architecture.md).
> This page is a quick map; if the two ever disagree, the ADR wins.

```
Flutter clients (desktop + mobile) ── thin, no DB credentials
        │  HTTPS / REST + JSON, bearer token
        ▼
FastAPI backend ── auth + all business logic
   ├─ Vault IO        (markdown files = source of truth, server-side)
   ├─ Chunker         (deterministic, word-budgeted, with overlap)
   ├─ Indexer         (file → chunk → embed → upsert; rebuild())
   ├─ EmbeddingService (Ollama local │ API fallback, dim pinned 768)
   ├─ Retrieval       (vector + FTS, reciprocal-rank fusion)
   └─ Postgres + pgvector   ← private, never exposed to clients
        ▲
        └─ docker-compose: db (pgvector/pg16) + backend; Ollama runs on host
```

## Component responsibilities

- **Vault (`services/vault.py`)** — the only writer of files. Serializes frontmatter +
  body, scans the vault for rebuild, parses notes back. Files are the truth.
- **Chunker (`services/chunker.py`)** — splits note text into embedding-sized chunks.
  Deterministic so `text_hash` can drive "only re-embed what changed."
- **Embeddings (`services/embeddings/`)** — `Embedder` interface; `OllamaEmbedder`
  (default) and `ApiEmbedder` (fallback); a factory selects by config. Every vector
  is validated against the pinned 768 dimension.
- **Indexer (`services/indexer.py`)** — keeps Postgres in sync with the vault. Upserts
  documents and chunks; re-embeds only changed chunks; `rebuild()` truncates and
  reconstructs the whole index from files.
- **Retrieval (`services/retrieval.py`)** — embeds the query, pulls vector candidates
  (HNSW) and FTS candidates, fuses them with RRF, returns one hit per document.
- **API (`api/routes.py`)** — public `/health`; token-guarded `/capture`, `/search`,
  `/documents/{id}`, `/admin/rebuild`.

## Repository layout

```
apps/pkm/
  .plan/                 # this folder — project plan
  docs/ADR-0001-architecture.md
  docker-compose.yml
  backend/               # FastAPI
    migrations/001_init.sql
    app/{api,models,services}/
    scripts/seed.py
    tests/
  app/                   # Flutter (desktop + mobile)
    lib/{core,features/{capture,search,document}}/
```

## Deployment model

- **Dev:** backend + Postgres via `docker compose up`; Ollama on the host (uses Mac
  GPU/Metal); phone points `API_BASE` at the Mac's LAN IP.
- **Always-on (optional, P2):** the same containers on a small cloud host; clients
  point at it, and managed Postgres (e.g. Neon) can replace the local DB. Moving
  Mac → cloud is environment config only.
