"""Shared singletons wired at startup and exposed as FastAPI dependencies."""
from __future__ import annotations

from .config import Settings, get_settings
from .db import pool
from .services.embeddings import Embedder, make_embedder
from .services.indexer import Indexer
from .services.title_gen import TitleGenerator
from .services.vault import Vault

_vault: Vault | None = None
_embedder: Embedder | None = None
_title_gen: TitleGenerator | None = None


def init_services(settings: Settings) -> None:
    global _vault, _embedder, _title_gen
    _vault = Vault(settings.vault_dir)
    _embedder = make_embedder(settings)
    if settings.title_provider == "api":
        _title_gen = TitleGenerator(
            provider="api",
            model=settings.title_model,
            base_url=settings.title_api_url,
            api_key=settings.title_api_key,
        )
    else:
        _title_gen = TitleGenerator(
            provider="ollama",
            model=settings.title_model,
            base_url=settings.ollama_url,
        )


def get_vault() -> Vault:
    assert _vault is not None, "services not initialised"
    return _vault


def get_embedder() -> Embedder:
    assert _embedder is not None, "services not initialised"
    return _embedder


def get_title_gen() -> TitleGenerator:
    assert _title_gen is not None, "services not initialised"
    return _title_gen


def get_indexer(settings: Settings = None) -> Indexer:  # type: ignore[assignment]
    settings = settings or get_settings()
    return Indexer(pool(), get_vault(), get_embedder())
