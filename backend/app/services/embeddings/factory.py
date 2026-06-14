from __future__ import annotations

from ...config import Settings
from .api import ApiEmbedder
from .base import Embedder
from .ollama import OllamaEmbedder


def make_embedder(settings: Settings) -> Embedder:
    if settings.embedder == "api":
        return ApiEmbedder(
            model=settings.api_embed_model,
            dim=settings.embed_dim,
            url=settings.api_embed_url,
            api_key=settings.api_embed_key,
        )
    # default: local Ollama
    return OllamaEmbedder(
        model=settings.embed_model,
        dim=settings.embed_dim,
        base_url=settings.ollama_url,
    )
