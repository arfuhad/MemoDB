# System Architecture

The project consists of a Flutter frontend (`app/`) and a FastAPI backend (`backend/`), communicating over HTTP.

## High-Level Design

### Frontend (Flutter)
- **Framework**: Flutter with Riverpod for state management.
- **Role**: Serves as the UI layer for the application, handling user interactions and presenting data.
- **Architecture**:
  - **Features**: Broken down by domain (`capture`, `notes`, `profile`, `search`, `document`).
  - **Core Layer**: Contains API clients (`api_client.dart`), shared models (`models.dart`), theme configuration, and Riverpod providers (`providers.dart`).
  - **Networking**: `ApiClient` acts as a thin wrapper around HTTP requests, abstracting the backend API interactions. State models reflect the API schemas.

### Backend (FastAPI)
- **Framework**: FastAPI (Python).
- **Role**: Handles business logic, data persistence, and external service integrations (e.g., embeddings and LLMs).
- **Architecture Layers**:
  - **API Layer** (`api/routes.py`): Exposes REST endpoints (e.g., `/capture`, `/search`, `/documents`). Validates inputs using Pydantic models (`schemas.py`).
  - **Services Layer**:
    - **Retrieval & Indexing**: Handles search queries (`retrieval.py`), chunking (`chunker.py`), and semantic indexing (`indexer.py`).
    - **Embeddings**: A factory pattern (`embeddings/factory.py`) supports local models (`ollama.py`) and remote fallback APIs (`api.py`), enabling pgvector indexing.
    - **Title Generation**: Uses `title_gen.py` to auto-generate titles via LLM APIs. Recently updated to support OpenRouter as the default remote API (`https://openrouter.ai/api/v1/chat/completions`).
    - **Vault**: Manages file storage (`vault.py`).
  - **Data Layer** (`db.py`): Manages PostgreSQL connections and transactions. Migrations are stored in `migrations/` (e.g., `001_init.sql`). Uses pgvector for semantic search.

## Data Flow
1. **User Interaction**: The user performs an action (e.g., saving a note) in the Flutter frontend.
2. **API Request**: `ApiClient` serializes the payload and sends an HTTP request to the FastAPI backend.
3. **Routing & Validation**: The backend API router validates the payload against `schemas.py` and delegates to the appropriate service.
4. **Processing**:
   - If generating embeddings, the system calls the local Ollama instance or falls back to remote APIs (like OpenAI).
   - If generating a title, the system queries the LLM API (configured for OpenRouter).
5. **Persistence**: Extracted vectors and metadata are stored in PostgreSQL via the Data Layer.
6. **Response**: The backend returns the serialized entities (e.g., `DocumentSummary`), which the Flutter client updates in its local Riverpod state.

## Separation of Concerns
- **UI State vs Remote State**: The Flutter app strictly separates Riverpod UI state from the API client. Clients never touch a local database—only the REST API.
- **Embeddings vs LLMs**: Handled by distinct, modular backend services. Fallbacks and remote configurations are isolated in their respective adapters (e.g., `embeddings/api.py`).
- **Database Migrations**: SQL migrations (`migrations/`) handle the schema setup exclusively, separate from the application models.
