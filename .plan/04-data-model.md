# Data Model

## Vault (source of truth)

```
vault/
  00-inbox/   # captures land here as <timestamp>-<slug>.md
  ...         # (PARA folders 01-projects … 04-archive arrive in P2 triage)
```

### Frontmatter contract (authoritative metadata)

```yaml
---
id: <uuid>                 # stable across rebuilds and devices
title: <string>           # derived from first line if not given
kind: text                # text | voice | image | video (only text in P1)
tags: [<string>, ...]
created: <ISO-8601>
updated: <ISO-8601>
---
<markdown body>
```

The body is plain markdown so any editor (Obsidian, vim) can read it. `content_hash`
(sha256 of the body) detects edits made outside the app.

## Database (derived index — rebuildable from the vault)

Full DDL: [`../backend/migrations/001_init.sql`](../backend/migrations/001_init.sql).
Key tables:

- **`users`** — single-user in P1, but `user_id` is on every table from day one
  (insurance against a future multi-user need). A seeded `local` user has a fixed id.
- **`documents`** — one row per note: `id` (mirrors frontmatter), `vault_path`,
  `kind`, `title`, `body_text`, `frontmatter` (jsonb), `content_hash`, timestamps, and
  a generated `fts` tsvector (GIN-indexed) for keyword search.
- **`chunks`** — embedding granularity: `document_id`, `ord`, `text`, `text_hash`,
  `embedding vector(768)`, `embedding_model`, `embedded_at`. HNSW index with
  `vector_cosine_ops` for fast approximate nearest-neighbour search.
- **`index_meta`** — bookkeeping (schema version, etc.).

### Design notes

- **Dimension pinned at 768.** The column is `vector(768)`; any embedder must emit 768.
  `embedding_model` records what produced each vector so a model change is detectable.
- **pgvector values are passed as text literals** (`"[...]"`) with explicit `::vector`
  casts at each call site, rather than a per-connection codec — this avoids racing the
  extension-creation migration at startup.
- **Chunks carry `text_hash`** so re-indexing a note only re-embeds the chunks that
  actually changed.
- **Everything here is disposable.** `POST /admin/rebuild` (or `Indexer.rebuild()`)
  truncates `documents` + `chunks` and reconstructs them from the vault. The
  rebuild-from-files parity check is the P1 proof that the DB is not authoritative.
