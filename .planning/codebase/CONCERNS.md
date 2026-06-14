# Codebase Concerns

This document outlines technical debt, architectural issues, missing tests, and security risks identified in the `app/` (Flutter) and `backend/` (FastAPI) codebases.

## 1. Security Risks
- **Hardcoded Authentication Token**: The application uses a hardcoded API token (`dev-local-token-change-me`) as its security boundary in both the backend (`backend/app/config.py`, `backend/app/auth.py`) and the frontend (`app/lib/core/config.dart`).
- **Open CORS Policy**: The FastAPI backend (`backend/app/main.py`) configures `CORSMiddleware` with `allow_origins=["*"]` and allows all methods/headers. This is a severe security risk if deployed beyond local development.
- **Missing Per-User Auth**: As noted in `backend/app/auth.py`, "Real per-user auth is a later phase." Currently, all operations assume a `LOCAL_USER_ID`, preventing multi-tenant or secure single-tenant deployments.

## 2. Architectural Issues & Technical Debt
- **Backend Function-Level Imports**: In `backend/app/api/routes.py`, `json` is imported multiple times inside individual endpoint functions (e.g., `list_documents`, `get_document`). These imports should be hoisted to the module level.
- **Frontend Error Swallowing**: In Flutter (e.g., `app/lib/features/document/document_screen.dart`), error handling frequently relies on silent catches (`catch (_) { // silently ignore }` or `// leave edit mode open so user can retry`). There's no robust user-facing error reporting or telemetry.
- **Frontend Logic Coupling**: The UI directly triggers data mutations on the REST client via `ref.read(apiClientProvider).updateDocument(...)` instead of abstracting operations into Riverpod Notifier classes.
- **Vault File Integrity**: The `Vault` class (`backend/app/services/vault.py`) generates files based on a UUID, timestamp, and title slug but does not explicitly check for file path collisions or handle concurrent writes to the same local directory safely.

## 3. Missing Tests
- **Flutter Widget Tests**: The frontend test suite is entirely missing. The only test file (`app/test/widget_test.dart`) is the default, boilerplate Flutter counter app test, which is completely irrelevant and out of sync with the actual PKM app.
- **Integration Coverage**: There are no integration tests validating the communication layer between the Flutter frontend and the FastAPI backend.

## 4. Known TODOs & FIXMEs
- **TODO (`backend/app/auth.py`)**: Implement real per-user authentication to replace the current single static bearer token.
- **TODO (`app/test/widget_test.dart`)**: Remove the broken counter app boilerplate test and implement actual widget and logic tests using `flutter_test`.