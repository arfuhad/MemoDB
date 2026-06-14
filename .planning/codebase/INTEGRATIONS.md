# Integrations

This document details the databases, third-party APIs, and external services integrated into the PKM system.

## Databases

### PostgreSQL + pgvector
- **Engine:** PostgreSQL 16
- **Extension:** `pgvector`
- **Purpose:** Primary database for storing PKM data and vector embeddings for semantic retrieval.
- **Docker Image:** `pgvector/pgvector:pg16`
- **Volume:** `pkm_pgdata`
- **Connection:** Accessed asynchronously from the backend using the `asyncpg` driver via `PKM_DATABASE_URL`.

## AI / ML Services

### Ollama (Embeddings)
- **Service:** Ollama
- **Model:** `nomic-embed-text` (Dimensions: 768)
- **Purpose:** Used by the backend to generate text embeddings for semantic search capabilities.
- **Deployment:** Intended to run directly on the host machine (e.g., leveraging Mac GPU/Metal via `host.docker.internal:11434`) rather than being containerized.
- **Configuration:** Managed via `PKM_EMBEDDER`, `PKM_OLLAMA_URL`, `PKM_EMBED_MODEL`, and `PKM_EMBED_DIM` environment variables.

## File System Integration

### Vault Directory
- **Purpose:** A dedicated file system directory configured for storing or processing raw PKM data/files.
- **Configuration:** Mounted into the backend container at `/data/vault` and controlled via the `PKM_VAULT_DIR` environment variable.
