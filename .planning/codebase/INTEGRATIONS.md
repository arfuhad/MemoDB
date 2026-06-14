# Integrations

## Databases
- **PostgreSQL**: The primary relational database, deployed via Docker (`pgvector/pgvector:pg16`).
- **pgvector**: A PostgreSQL extension used to store vector embeddings (768 dimensions for `nomic-embed-text` compatibility) and perform semantic similarity searches.

## File System
- **Vault Directory**: The application interacts directly with a local file system directory (configured via `PKM_VAULT_DIR`, defaults to `./vault`) to persist and retrieve Markdown notes. Configuration overrides can also be loaded from a `settings.json` file stored within this vault.

## AI & Third-Party APIs

The backend integrates with both local and external AI services for semantic processing, controlled by the `config.py` settings.

### 1. Local AI Service
- **Ollama**:
  - **Purpose**: Local processing for both embeddings and title generation to ensure privacy and avoid API costs.
  - **Integration**: Communicates over HTTP (default `http://localhost:11434` or `host.docker.internal:11434`).
  - **Models**: Configured to use `nomic-embed-text` for vectorization and `gemma4:latest` for text generation.

### 2. External AI APIs
- **OpenRouter**:
  - **Purpose**: Used for text generation tasks (specifically title generation) when configured to use the `"api"` provider fallback instead of `"ollama"`.
  - **Integration**: Pointed to `https://openrouter.ai/api/v1/chat/completions`. Requires an API key (`PKM_TITLE_API_KEY`).
- **OpenAI (or Compatible APIs)**:
  - **Purpose**: Used for generating text embeddings when the embedder provider is set to `"api"`.
  - **Integration**: Defaults to `https://api.openai.com/v1/embeddings` using the `text-embedding-3-small` model. Requires an API key (`PKM_API_EMBED_KEY`).
