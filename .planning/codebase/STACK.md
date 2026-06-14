# Stack

This document outlines the primary languages, frameworks, libraries, and tools used in the PKM system.

## Frontend (App)
The frontend is a multi-platform client (desktop + mobile) built with Flutter.

- **Language:** Dart (`>=3.4.0`)
- **Framework:** Flutter
- **State Management:** Riverpod (`flutter_riverpod ^2.5.1`)
- **Networking:** `http (^1.2.0)`
- **Localization/Formatting:** `intl (^0.19.0)`
- **Testing & Linting:** `flutter_test`, `flutter_lints`

## Backend
The backend is a high-performance semantic capture and retrieval API.

- **Language:** Python (`>=3.11`)
- **Framework:** FastAPI (`>=0.111`)
- **Server:** Uvicorn (`>=0.30` with `standard` extras)
- **Data Validation & Settings:** Pydantic (`>=2.7`), Pydantic Settings (`>=2.3`)
- **Database Driver:** `asyncpg` (`>=0.29`)
- **HTTP Client:** `httpx` (`>=0.27`)
- **Markdown & Metadata parsing:** `python-frontmatter` (`>=1.1`), `pyyaml` (`>=6.0`)
- **Testing:** `pytest` (`>=8.2`), `pytest-asyncio` (`>=0.23`)

## Infrastructure & DevOps
- **Containerization:** Docker (`python:3.11-slim` base image for the backend).
- **Orchestration:** Docker Compose is used for local development and coordinating the backend API with the database.
