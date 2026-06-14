# Stack

## Client App (Frontend)
- **Language**: Dart (SDK >=3.4.0 <4.0.0)
- **Framework**: Flutter
- **State Management**: Riverpod (`flutter_riverpod`)
- **Key Libraries**:
  - `http` for API communication
  - `intl` for localization

## Backend
- **Language**: Python >= 3.11
- **Framework**: FastAPI (run via Uvicorn)
- **Core Libraries**:
  - `asyncpg` for asynchronous PostgreSQL database interaction
  - `pydantic` and `pydantic-settings` for data validation and configuration management
  - `httpx` for making outgoing HTTP requests (e.g., to AI services)
  - `python-frontmatter` and `pyyaml` for parsing Markdown and YAML
  - `pytest` and `pytest-asyncio` for testing

## Infrastructure & DevOps
- **Containerization**: Docker and Docker Compose
- **Database Server**: PostgreSQL 16 with `pgvector` extension (`pgvector/pgvector:pg16`)

## AI and Models Stack (Ollama vs OpenRouter/API)
The application leverages dual configurations for AI-driven tasks (embeddings and title generation):
- **Ollama (Default & Local)**:
  - Designed to run on the host machine to leverage hardware acceleration (e.g., Mac GPU/Metal).
  - Backend accesses it via `host.docker.internal:11434`.
  - Uses `nomic-embed-text` for embeddings (768 dimensions).
  - Uses `gemma4:latest` for semantic title generation.
- **OpenRouter & API (Fallback/External)**:
  - OpenRouter is the default target for external API-based title generation (`https://openrouter.ai/api/v1/chat/completions`).
  - Standard OpenAI-compatible endpoints are supported for embeddings fallback (defaulting to `text-embedding-3-small`).
