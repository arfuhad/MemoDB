# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PKM is a personal knowledge management system. P1 scope: text capture + meaning-based retrieval. The core bet: *find a note by what it means, not by remembering its words.*

Stack: FastAPI backend (Python 3.11+) · Postgres 16 + pgvector · Ollama embeddings · Flutter clients (desktop + mobile).

## Commands

### Backend

```bash
# Run everything via Docker (Postgres + backend on :8000):
docker compose up --build

# Or run backend directly (Postgres still via compose):
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Tests (requires Postgres + Ollama running):
pytest

# Single test file:
pytest tests/test_chunker.py

# Seed ~20 notes and run meaning-based queries:
python scripts/seed.py

# Rebuild the index from vault (prove DB is disposable):
curl -X POST localhost:8000/admin/rebuild \
  -H "Authorization: Bearer dev-local-token-change-me"
```

Ollama must be running on the host (`ollama serve`) with `nomic-embed-text` pulled.

### Flutter client

```bash
cd app
flutter pub get
flutter run -d macos \
  --dart-define=API_BASE=http://localhost:8000 \
  --dart-define=API_TOKEN=dev-local-token-change-me

# Analyze:
dart analyze
```

## Architecture

```
Flutter clients (desktop + mobile)
    │  HTTPS + Bearer token
    ▼
FastAPI backend
   ├─ Vault (markdown files = source of truth)
   ├─ Indexer + Chunker  ──► Postgres (derived, rebuildable)
   ├─ EmbeddingService (Ollama local │ API fallback)
   └─ Retrieval (vector cosine + FTS via RRF)
```

### The file-first invariant

**Every write persists the markdown file before touching Postgres.** The vault (`backend/vault/` by default, or `PKM_VAULT_DIR`) is the authoritative store. The Postgres DB is a derived index that can be dropped and rebuilt with `POST /admin/rebuild`. Never make Postgres the source of truth for a document.

### Backend layout

| Path | Purpose |
|------|---------|
| `app/services/vault.py` | Markdown file IO — creates/reads `.md` files with YAML frontmatter |
| `app/services/indexer.py` | Upserts documents + chunks to Postgres; `rebuild()` truncates and re-indexes from vault |
| `app/services/chunker.py` | Deterministic paragraph-aware splitter (380 words, 40-word overlap) |
| `app/services/retrieval.py` | Hybrid search: cosine vector (HNSW) + FTS fused via Reciprocal Rank Fusion (RRF_K=60) |
| `app/services/embeddings/` | `Embedder` ABC → `OllamaEmbedder` (default) or `ApiEmbedder` (OpenAI/Voyage), selected by factory |
| `app/api/routes.py` | Two routers: `public` (no auth) and `api` (bearer token required) |
| `app/config.py` | Pydantic-settings; all env vars use `PKM_` prefix |
| `app/db.py` | asyncpg pool; pgvector encoded as text literals (`"[1.0,2.0]"`) with `::vector` cast at each call site |
| `backend/migrations/` | Idempotent SQL (all `IF NOT EXISTS`); applied at startup by `run_migrations()` and also by Docker entrypoint |

### Embedding dimension is pinned at 768

`vector(768)` is hardcoded in the schema and the `embed_dim` setting. Changing models requires a migration + full re-embed. The `embedding_model` column on `chunks` records the model so a mismatch is detectable.

### Chunking is deterministic

The chunker uses `text_hash` to skip re-embedding unchanged chunks. Any change to chunking logic invalidates all stored hashes — run `admin/rebuild` after.

### pgvector encoding

pgvector values are always passed as text strings (`"[1.0,2.0,3.0]"`) with an explicit `::vector` cast in SQL. Do not use per-connection type codecs; they race the extension-creation migration at startup.

### Flutter client

`AppConfig` (`lib/core/config.dart`) reads `API_BASE` and `API_TOKEN` from `--dart-define`. `ApiClient` (`lib/core/api_client.dart`) is the only HTTP layer — all backend calls go through it. State is managed with Riverpod (`lib/core/providers.dart`).

### Auth (P1)

Static bearer token (`PKM_API_TOKEN`). `/health` is unauthenticated; all other endpoints require the token. Real auth is explicitly out of P1 scope.

### P1 scope boundaries

Out of scope until the P1 bet holds: voice/image/video ingestion, tasks, bidirectional links, PARA triage, daily notes, cross-device sync, real authentication. Don't build toward these.
