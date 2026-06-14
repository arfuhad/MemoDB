# Directory Structure & Module Boundaries

The project is divided into two top-level directories representing the main system boundaries: `app/` (the Flutter frontend) and `backend/` (the FastAPI Python backend).

## `app/` - Flutter Frontend

The Flutter application follows a feature-driven architecture, separating core infrastructure from specific UI domains.

```
app/lib/
├── main.dart                 # Application entry point
├── app.dart                  # Root widget and app configuration
│
├── core/                     # Shared infrastructure and configuration
│   ├── api_client.dart       # HTTPS REST client and Bearer token injection
│   ├── config.dart           # App-wide configuration/environment variables
│   ├── models.dart           # Shared Dart data models (JSON deserialization)
│   ├── providers.dart        # Global state management providers
│   └── theme.dart            # Centralized UI styling and theming
│
└── features/                 # Feature-sliced UI domains
    ├── capture/              # Input screens for new thoughts/notes
    │   └── capture_screen.dart
    ├── document/             # Detailed view/editor for specific documents
    │   └── document_screen.dart
    ├── notes/                # General list/browsing views
    │   └── notes_screen.dart
    └── search/               # Hybrid semantic/FTS search interface
        └── search_screen.dart
```

### Frontend Module Boundaries
*   **Core:** Independent of any specific UI screen. It handles network coordination, global state, and system-wide styles.
*   **Features:** Self-contained UI slices. Features communicate with the backend strictly through the `core/api_client.dart` and share state via `core/providers.dart`.

---

## `backend/` - FastAPI Backend

The Python backend is structured around a typical FastAPI layout, prioritizing the separation of API routing, business services, and database configuration.

```
backend/app/
├── main.py                   # FastAPI application initialization & routing inclusion
├── config.py                 # Pydantic BaseSettings and env config
├── auth.py                   # Bearer token validation logic
├── deps.py                   # FastAPI dependency injections (DB sessions, current user)
├── db.py                     # SQLAlchemy setup and PostgreSQL connection logic
│
├── api/                      # Routing Layer
│   └── routes.py             # REST API endpoints exposed to the Flutter app
│
├── models/                   # Data Layer definitions
│   └── schemas.py            # Pydantic models for API request/response validation
│
└── services/                 # Business Logic Layer
    ├── vault.py              # File I/O for the Markdown source-of-truth
    ├── chunker.py            # Text splitting and markdown parsing for embeddings
    ├── indexer.py            # Syncs vault files to the Postgres pgvector index
    ├── retrieval.py          # Hybrid search logic (Vector Cosine/HNSW + Postgres FTS)
    ├── title_gen.py          # Automatic title generation logic for untitled notes
    │
    └── embeddings/           # Embedding Model Integration
        ├── base.py           # Abstract base class/interface for embedders
        ├── factory.py        # Initializes the configured embedder (Local vs API)
        ├── ollama.py         # Local Ollama integration (nomic-embed-text)
        └── api.py            # Fallback cloud API integration (OpenAI/Voyage)
```

### Backend Module Boundaries
*   **Root Files:** Handle application lifecycle, global security (auth), and database connectivity.
*   **API (`api/`):** Strictly responsible for HTTP request handling and response formatting. Must delegate complex operations to `services/`.
*   **Services (`services/`):** The core of the system. `vault.py` strictly manages the file system invariant, while `indexer.py` handles the downstream sync to the database.
*   **Embeddings Sub-module:** Encapsulates external AI models, exposing a uniform `base.py` interface to `indexer.py` and `retrieval.py` to prevent tight coupling to Ollama or OpenAI.