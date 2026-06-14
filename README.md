# PKM — Personal Knowledge Management (P1)

Semantic capture & retrieval. Type text; later, find it by *meaning*.
Markdown files are the source of truth; Postgres + pgvector is a rebuildable index.

See [`docs/ADR-0001-architecture.md`](docs/ADR-0001-architecture.md) for the design
and the decisions behind it.

## Stack

- **Backend:** FastAPI (Python), asyncpg, Postgres 16 + pgvector
- **Embeddings:** Ollama `nomic-embed-text` (local, 768-dim) · API fallback
- **Clients:** Flutter (desktop + mobile), thin, bearer-token auth

## Quick start (dev, on your Mac)

### 1. Embedding model (host)

```bash
# Install Ollama from https://ollama.com, then:
ollama pull nomic-embed-text
ollama serve            # listens on :11434
```

### 2. Backend + database

```bash
cd apps/pkm
docker compose up --build        # starts Postgres (pgvector) + backend on :8000
```

Or run the backend directly (Postgres still via compose):

```bash
cd apps/pkm/backend
python -m venv .venv && source .venv/bin/activate
pip install -e .
cp .env.example .env             # edit if needed
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Health check: `curl localhost:8000/health`

### 3. Flutter client

```bash
cd apps/pkm/app
flutter pub get
# Desktop:
flutter run -d macos
# Mobile (phone on same WiFi): point API_BASE at your Mac's LAN IP, then
flutter run -d <device>
```

The client reads the backend URL and token from `--dart-define`:

```bash
flutter run -d macos \
  --dart-define=API_BASE=http://localhost:8000 \
  --dart-define=API_TOKEN=dev-local-token-change-me
```

## API (P1)

| Method | Path             | Purpose                                  |
|--------|------------------|------------------------------------------|
| GET    | `/health`        | liveness + embedder/db status            |
| POST   | `/capture`       | save text → file → chunk → embed → index |
| GET    | `/search?q=...`  | hybrid (vector + FTS) semantic search    |
| GET    | `/documents/{id}`| fetch one document                       |
| POST   | `/admin/rebuild` | rebuild the index from the vault         |

All endpoints except `/health` require `Authorization: Bearer <PKM_API_TOKEN>`.

## Tests

```bash
cd apps/pkm/backend
pip install -e ".[dev]"
pytest                 # chunker, embedder interface, vault round-trip
```

## Verify the bet (relevance + rebuildability)

With the backend running and Ollama up:

```bash
cd apps/pkm/backend
python scripts/seed.py        # seeds ~20 notes, runs meaning-based queries

# Prove the index is disposable — rebuild it from the markdown vault:
curl -X POST localhost:8000/admin/rebuild \
  -H "Authorization: Bearer dev-local-token-change-me"
```

The done-bar is met when a query like *"how do I remember things long term"*
surfaces the spaced-repetition / forgetting-curve notes without sharing their words.

## What is verified vs. what you run

Built and statically checked here: all backend modules compile; chunker, snippet,
overlap, and pgvector-encoding logic pass. **Not run here** (needs your machine —
this sandbox has no PyPI, Flutter SDK, Postgres, or Ollama): full `pytest`,
`dart analyze`, and the end-to-end flow. Run those locally per the steps above.
