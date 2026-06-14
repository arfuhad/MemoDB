# Codebase Concerns

## Technical Debt & Code Quality
- **Missing Tests:**
  - **Flutter:** The app currently has zero tests (unit, widget, or integration). The `test/` directory is essentially empty.
  - **FastAPI:** Test coverage is limited to embeddings (`test_embedder.py`), chunking (`test_chunker.py`), and the vault (`test_vault_roundtrip.py`). The core API endpoints, config state management, and authentication are not covered by automated tests.
- **Error Handling:** Some services simply print exceptions to stdout (e.g., `title_gen.py`) instead of using structured logging. 

## Architectural Issues
- **Single-Tenant & Static Auth:** The system currently relies on a single hardcoded bearer token (`dev-local-token-change-me`) injected via environment variables (`.env` or `--dart-define`) to establish the security boundary between the client and database. Moving to multi-tenancy or per-user real authentication is deferred to a future phase.
- **Config Mutability & State Management:** Dynamic configuration (e.g. switching between local Ollama and OpenRouter/OpenAI) mutates the singleton `Settings` in-memory and re-initializes all service Singletons via `init_services()`. Concurrency issues might arise during `init_services(new_settings)` if an async request is actively processing, as dependencies are swapped globally mid-flight.

## Security Risks
- **API Keys Stored in Plain Text:** 
  - The API keys for embeddings (`api_embed_key`) and title generation (`title_api_key`) are saved in plaintext to `vault/settings.json` when the application config is updated. Anyone with filesystem access to the vault can read these keys.
- **API Keys Exposed in GET Endpoint:** 
  - The `GET /config` endpoint (`get_app_config` in `backend/app/api/routes.py`) returns the application configuration including the `title_api_key` and `api_embed_key` in plaintext. These should be redacted (e.g., masked or returning a boolean if set) and only accept updates via the `PUT /config` endpoint.
- **Hardcoded Default Secrets:** The static `api_token` falls back to `dev-local-token-change-me` on both the frontend and backend if not properly overridden.
- **CORS Permissiveness:** The FastAPI backend is configured with `allow_origins=["*"]`. While the client is a native Flutter app (which doesn't enforce CORS), if the backend is exposed publicly or a web client is added, this open CORS policy is a risk.
