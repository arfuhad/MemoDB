# Testing Strategy

## Frontend (Flutter / Dart)

### Framework
- Uses the standard `flutter_test` package.

### Directory Structure
- All tests reside in `app/test/`.
- Test files suffix with `_test.dart` (e.g., `widget_test.dart`).

### Strategy
- **Widget Testing**: Tests utilize `WidgetTester` to verify UI rendering, interactions (like taps), and state changes without needing an emulator or real device.
- Standard `expect` matchers (`findsOneWidget`, `findsNothing`) are used.

## Backend (Python)

### Framework
- Uses `pytest` (>=8.2) combined with `pytest-asyncio` (>=0.23).
- `pytest.ini_options` configures `asyncio_mode = "auto"`, meaning async test functions are automatically detected and run.

### Directory Structure
- Tests reside in `backend/tests/`.
- Test files are prefixed with `test_` (e.g., `test_vault_roundtrip.py`, `test_chunker.py`, `test_embedder.py`).

### Strategy
- **Service/Logic Testing**: Tests cover business logic by validating classes directly (e.g., testing the `Vault` service).
- **Fixtures**: Standard Pytest fixtures are used, like `tmp_path` for isolated file-system tests without side effects.
- Tests verify expected states with simple `assert` statements instead of complex matchers.
