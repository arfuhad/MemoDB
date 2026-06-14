"""Embedding interface. Local (Ollama) is the default; an API implementation
sits behind the same contract so it can be swapped per the config. Every
implementation MUST return vectors of exactly `dim` floats (pinned at 768)."""
from __future__ import annotations

from abc import ABC, abstractmethod


class EmbeddingError(RuntimeError):
    pass


class Embedder(ABC):
    name: str = "base"

    def __init__(self, model: str, dim: int):
        self.model = model
        self.dim = dim

    @abstractmethod
    async def embed(self, texts: list[str]) -> list[list[float]]:
        """Return one `dim`-length vector per input text, order preserved."""

    async def embed_one(self, text: str) -> list[float]:
        return (await self.embed([text]))[0]

    def _check_dim(self, vectors: list[list[float]]) -> list[list[float]]:
        for v in vectors:
            if len(v) != self.dim:
                raise EmbeddingError(
                    f"{self.name} returned dim={len(v)}, expected {self.dim}. "
                    "Embedding dimension is pinned; reconcile model/column."
                )
        return vectors

    async def health(self) -> bool:
        try:
            await self.embed_one("healthcheck")
            return True
        except Exception:
            return False
