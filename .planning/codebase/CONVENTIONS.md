# Codebase Conventions

## Overview
The project is organized into two main parts:
- `app/`: The frontend mobile application built with Flutter/Dart.
- `backend/`: The backend API built with Python, FastAPI, and asyncpg.

## Frontend (Flutter / Dart)

### Structure
- `app/lib/`: Main source directory containing the Dart code.
  - `core/`: Core utilities and cross-cutting concerns.
  - `features/`: Feature-based modular code.
- `app/test/`: Contains unit and widget tests.

### Linting and Formatting
- The project uses standard Flutter lint rules defined by `package:flutter_lints/flutter.yaml`.
- **Overrides** in `analysis_options.yaml`:
  - `prefer_const_constructors`: Enforced (`true`) to optimize UI rebuilding and memory usage.
  - `avoid_print`: Disabled (`false`), allowing `print()` statements (likely for debugging/development ease).

### Naming & Style
- Standard Dart conventions apply: `CamelCase` for classes, `camelCase` for variables/methods, `snake_case` for file names and directories.
- Strong emphasis on immutability and `const` widgets.

## Backend (Python)

### Structure
- `backend/app/`: The main application code.
  - `api/`: FastAPI route handlers and controllers.
  - `models/`: Pydantic models (using Pydantic V2) for validation and serialization.
  - `services/`: Business logic (e.g., Vault operations).
- `backend/scripts/`: Utility scripts (e.g., `seed.py`).
- `backend/tests/`: Pytest suite.

### Tech Stack and Patterns
- **Framework**: FastAPI (>=0.111).
- **Database**: `asyncpg` for asynchronous PostgreSQL access.
- **Data Validation**: `pydantic` (>=2.7) and `pydantic-settings`.
- **Dependency Injection**: Dependencies and system wiring are centralized in `app/deps.py`.

### Linting and Formatting
- Project dependencies are managed via standard `pyproject.toml`.
- Requires Python 3.11+.
- Standard Python type-hinting conventions should be utilized.
