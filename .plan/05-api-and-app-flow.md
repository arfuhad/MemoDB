# API & App Flow

## API surface (P1)

| Method | Path              | Auth   | Purpose                                        |
|--------|-------------------|--------|------------------------------------------------|
| GET    | `/health`         | none   | liveness + embedder/db status + document count |
| POST   | `/capture`        | bearer | save text → file → chunk → embed → index       |
| GET    | `/search?q=&limit=` | bearer | hybrid (vector + FTS) semantic search        |
| GET    | `/documents/{id}` | bearer | fetch one document                             |
| POST   | `/admin/rebuild`  | bearer | rebuild the index from the vault               |

All non-public endpoints require `Authorization: Bearer <PKM_API_TOKEN>`.

### Request/response shapes

- `POST /capture` → `{ text, title?, tags[] }` → `201 { id, title, vault_path, created_at, updated_at }`
- `GET /search` → `{ query, hits: [{ document_id, title, snippet, score, vector_rank, keyword_rank }] }`
- `GET /documents/{id}` → `{ id, title, body_text, frontmatter, tags, created_at, updated_at }`

## End-to-end flow

```
CAPTURE   client → POST /capture
          → backend writes 00-inbox/<id>.md  (FILE = truth)
          → Indexer upserts document, chunks it, embeds changed chunks,
            stores vectors in Postgres
          → 201 with the new document summary

RETRIEVE  client → GET /search?q=...
          → backend embeds the query (same model)
          → vector candidates (cosine / HNSW) + FTS candidates
          → reciprocal-rank fusion → one hit per document, ranked
          → client lists hits with semantic/keyword match badges

READ      client → GET /documents/{id}
          → backend returns the document; client shows title, tags, body

RECONCILE external edits (Obsidian/vim) change a file
          → content_hash differs → Indexer re-chunks and re-embeds only
            the chunks that changed
          → /admin/rebuild is always the full escape hatch
```

## Client (Flutter)

Two tabs, plus a detail screen:

- **Capture** — autofocused text field; ⌘/Ctrl+Enter saves; status line confirms.
  Deliberately the cheapest action in the app (capture friction kills PKMs).
- **Search** — query field; results list with a semantic (✦) / keyword (abc) badge
  per hit; tap to open.
- **Document** — read view with title, tags, selectable body.

Backend URL and token are injected at build time via `--dart-define` (`API_BASE`,
`API_TOKEN`). On a phone, `API_BASE` is the Mac's LAN address (or a cloud host later).
