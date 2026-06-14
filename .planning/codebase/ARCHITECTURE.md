# System Architecture

## High-Level Design

The system is a personal knowledge management (PKM) tool designed around a "Retrieve-by-meaning" philosophy. Currently in Phase 1 (P1), the system focuses exclusively on text ingestion and semantic retrieval.

At a high level, the architecture enforces a strict **"File first, index second"** invariant. The true source of truth is a file system of Markdown files (with YAML frontmatter) managed by the backend. A PostgreSQL database with `pgvector` serves merely as a derived, rebuildable index for fast semantic and full-text search.

The system is split into two primary boundaries:
1.  **FastAPI Backend (Python):** Owns all business logic, data persistence (vault files + database indexing), embeddings generation, and search retrieval.
2.  **Flutter Clients (Dart):** Thin frontend applications (desktop and mobile) that contain no direct database access or embedding models, communicating with the backend over HTTPS REST.

## Core Layers & Data Flow

### 1. The Frontend (Flutter `app/`)
*   **Role:** Thin client responsible for user interactions (capture, search, viewing notes).
*   **Security:** Holds no database credentials. Uses a static bearer token for authentication.
*   **Network:** Communicates entirely via HTTPS REST + JSON to the FastAPI backend.

### 2. The Backend (FastAPI `backend/`)
*   **Role:** API gateway, security boundary, and business logic coordinator.
*   **Auth:** Validates the static bearer token.
*   **Services:**
    *   **Vault IO:** Reads and writes Markdown files to disk.
    *   **Indexer & Chunker:** Parses Markdown files, chunks text, and coordinates embeddings.
    *   **Embedding Service:** Connects to either local Ollama (running `nomic-embed-text`) or an API fallback (e.g., OpenAI/Voyage) to generate 768-dimensional vector embeddings.
    *   **Retrieval:** Implements hybrid search, fusing vector similarity (cosine/HNSW) with PostgreSQL Full-Text Search (FTS) via Reciprocal Rank Fusion (RRF).

### 3. The Data Layer
*   **Source of Truth (The Vault):** Markdown files on disk. Every write persists here first.
*   **The Index (PostgreSQL + pgvector):** Stores metadata, extracted text chunks, and vector embeddings. It is entirely disposable; if dropped, the backend can reconstruct the entire database by re-reading the Vault.

## Separation of Concerns

*   **State Management:** The Flutter app uses providers for local state and API clients for remote state. It offloads all heavy lifting (search ranking, parsing, embeddings) to the backend.
*   **Storage Invariants:** The backend separates file I/O from database indexing. The database is never authoritative. This completely sidesteps complex offline-merge logic for P1.
*   **Embeddings Abstraction:** The embedding generation is abstracted behind an interface (`base.py`), allowing a seamless swap between local models and cloud APIs without affecting the indexer or the routes.

## Deployment Context (P1)
In Phase 1, the backend runs locally (e.g., on a Mac), with desktop clients connecting via `localhost` and mobile clients connecting over the LAN IP. Cloud deployment is an optional P2 consideration.