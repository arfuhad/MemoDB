-- PKM P1 schema — derived, rebuildable index over the markdown vault.
-- The vault (files on disk) is the source of truth; everything here is reconstructable.

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ── users ────────────────────────────────────────────────────────────────────
-- Single-user in P1, but user_id lives on every table from day one (insurance).
CREATE TABLE IF NOT EXISTS users (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  handle     text UNIQUE NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Seed the local default user (stable id so the backend can rely on it).
INSERT INTO users (id, handle)
VALUES ('00000000-0000-0000-0000-000000000001', 'local')
ON CONFLICT (handle) DO NOTHING;

-- ── documents ────────────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE artifact_kind AS ENUM ('text','voice','image','video'); -- only 'text' in P1
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS documents (
  id           uuid PRIMARY KEY,                 -- mirrors frontmatter `id`
  user_id      uuid NOT NULL REFERENCES users(id),
  vault_path   text NOT NULL,                    -- relative path within the vault
  kind         artifact_kind NOT NULL DEFAULT 'text',
  title        text NOT NULL,
  body_text    text NOT NULL DEFAULT '',         -- extracted plain text (FTS + rebuild)
  frontmatter  jsonb NOT NULL DEFAULT '{}',
  content_hash text NOT NULL,                     -- detects external edits
  created_at   timestamptz NOT NULL,
  updated_at   timestamptz NOT NULL,
  fts          tsvector GENERATED ALWAYS AS
                 (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(body_text,''))) STORED,
  UNIQUE (user_id, vault_path)
);
CREATE INDEX IF NOT EXISTS documents_fts_idx   ON documents USING gin (fts);
CREATE INDEX IF NOT EXISTS documents_title_trgm ON documents USING gin (title gin_trgm_ops);

-- ── chunks (embedding granularity) ───────────────────────────────────────────
-- Embedding dimension is PINNED at 768 (nomic-embed-text). An API fallback must
-- emit 768 (e.g. OpenAI text-embedding-3-small with dimensions=768).
CREATE TABLE IF NOT EXISTS chunks (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id         uuid NOT NULL REFERENCES users(id),
  document_id     uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  ord             int  NOT NULL,                 -- position within the document
  text            text NOT NULL,
  text_hash       text NOT NULL,                 -- skip re-embedding unchanged chunks
  embedding       vector(768),                   -- null until embedded
  embedding_model text,
  embedded_at     timestamptz,
  UNIQUE (document_id, ord)
);
CREATE INDEX IF NOT EXISTS chunks_doc_idx ON chunks (document_id);
-- HNSW for fast approximate cosine NN. Tolerates null embeddings (simply unindexed).
CREATE INDEX IF NOT EXISTS chunks_embedding_hnsw
  ON chunks USING hnsw (embedding vector_cosine_ops);

-- ── index bookkeeping ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS index_meta (
  key   text PRIMARY KEY,
  value text NOT NULL
);
INSERT INTO index_meta (key, value) VALUES ('schema_version', '1')
ON CONFLICT (key) DO NOTHING;
