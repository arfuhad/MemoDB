# Testing Setup and Strategy

## Dart / Flutter (`app/`)
- **Test Directory:** `app/test/`
- **Framework:** Standard Flutter `test` / `flutter_test`.
- **Strategy:** Includes `widget_test.dart` for widget-level testing. Focus on component and UI testing using Flutter's built-in testing tools.

## Python / FastAPI (`backend/`)
- **Test Directory:** `backend/tests/`
- **Framework:** `pytest` (>=8.2) with `pytest-asyncio` (>=0.23) for asynchronous testing.
- **Configuration:** `asyncio_mode = "auto"` and `testpaths = ["tests"]` defined in `pyproject.toml`.
- **Strategy:** Contains unit tests such as `test_vault_roundtrip.py`, `test_embedder.py`, and `test_chunker.py`. Tests focus on specific backend functionality and data flows.
