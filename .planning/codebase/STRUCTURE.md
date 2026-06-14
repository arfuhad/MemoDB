# Directory Structure & Module Boundaries

The repository is divided into two primary workspaces: `app/` for the mobile/desktop frontend and `backend/` for the API and logic engine.

## Frontend (`app/`)

The frontend is a Flutter application organized primarily by feature domain.

```text
app/
├── lib/
│   ├── app.dart              # Root application widget (MaterialApp configuration)
│   ├── main.dart             # Entry point (runApp and ProviderScope)
│   ├── core/                 # Shared domain models, API clients, and theme logic
│   │   ├── api_client.dart   # Thin wrapper around HTTP calls to the backend
│   │   ├── config.dart       # Environment and API base URL configurations
│   │   ├── models.dart       # Dart implementations of backend schemas (Pydantic models)
│   │   ├── providers.dart    # Shared Riverpod providers and state
│   │   └── theme.dart        # Global styling and colors
│   └── features/             # Feature-specific UI code
│       ├── capture/          # Note/document creation
│       ├── document/         # Document details and reading view
│       ├── notes/            # List/grid view of saved notes
│       ├── profile/          # User settings and API overrides (e.g., OpenRouter URL)
│       └── search/           # Semantic search UI and results
├── test/                     # Widget and unit tests
├── macos/                    # Native build runners for macOS
├── pubspec.yaml              # Flutter dependencies
└── analysis_options.yaml     # Dart linting configuration
```

## Backend (`backend/`)

The backend is a FastAPI Python application adhering to a layered architectural pattern.

```text
backend/
├── app/
│   ├── main.py               # FastAPI application setup, lifecycle, and CORS configuration
│   ├── config.py             # Pydantic BaseSettings for environment variables (OpenRouter, URLs)
│   ├── db.py                 # PostgreSQL connection pooling and pgvector integration
│   ├── deps.py               # FastAPI dependency injection definitions
│   ├── auth.py               # Token verification middleware
│   ├── api/                  # API routing layer
│   │   └── routes.py         # REST endpoints mapping to backend services
│   ├── models/               # Data definitions
│   │   └── schemas.py        # Pydantic schemas for request/response validation
│   └── services/             # Core business logic
│       ├── chunker.py        # Text segmentation for semantic search
│       ├── indexer.py        # Pipeline orchestrator for inserting vector data
│       ├── retrieval.py      # Semantic similarity and search query construction
│       ├── title_gen.py      # Title extraction logic via LLMs (configured for OpenRouter)
│       ├── vault.py          # File persistence and storage logic
│       └── embeddings/       # Embeddings factory pattern
│           ├── api.py        # Remote API fallback logic
│           ├── base.py       # Abstract base classes for embedders
│           ├── factory.py    # Embedder instantiation based on settings
│           └── ollama.py     # Local Ollama embedding integration
├── migrations/               # PostgreSQL schema migrations
│   └── 001_init.sql          # Initial database schema and pgvector setup
├── scripts/                  # Utilities
│   └── seed.py               # Database seeding and test fixture generators
├── tests/                    # Pytest suite testing services and routing
├── pyproject.toml            # Python dependencies and build system
└── Dockerfile                # Production container build script
```

## Module Boundaries

1. **Flutter vs FastAPI**: Complete decoupling. The Flutter app has no direct database access and interacts strictly over REST API calls authenticated via bearer tokens.
2. **Features (Flutter)**: Isolated by directory under `lib/features/`. Each feature handles its own UI components, delegating cross-cutting concerns (like state and networking) to `lib/core/`.
3. **Services (FastAPI)**: Business logic is decoupled from HTTP transport. `api/routes.py` manages requests and delegates execution to `services/` (e.g., `title_gen.py` handling OpenRouter prompts or `embeddings/factory.py` abstracting the choice of vectorization).
4. **Data Isolation (FastAPI)**: Schema definitions (`models/schemas.py`) define API contracts independently of the database driver functions in `db.py` and `migrations/`.
