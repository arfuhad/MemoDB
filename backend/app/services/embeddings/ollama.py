"""Local embeddings via Ollama (default). Calls the host Ollama server's
/api/embeddings endpoint, one request per text (Ollama's embeddings endpoint is
single-input). Vectors are validated against the pinned dimension."""
from __future__ import annotations

import httpx

from .base import Embedder, EmbeddingError


class OllamaEmbedder(Embedder):
    name = "ollama"

    def __init__(self, model: str, dim: int, base_url: str):
        super().__init__(model, dim)
        self.base_url = base_url.rstrip("/")

    async def embed(self, texts: list[str]) -> list[list[float]]:
        if not texts:
            return []
        vectors: list[list[float]] = []
        async with httpx.AsyncClient(timeout=60.0) as client:
            for text in texts:
                try:
                    resp = await client.post(
                        f"{self.base_url}/api/embeddings",
                        json={"model": self.model, "prompt": text},
                    )
                    resp.raise_for_status()
                    data = resp.json()
                except httpx.HTTPError as exc:
                    raise EmbeddingError(f"Ollama request failed: {exc}") from exc
                vec = data.get("embedding")
                if not isinstance(vec, list):
                    raise EmbeddingError(f"Ollama returned no embedding: {data}")
                vectors.append([float(x) for x in vec])
        return self._check_dim(vectors)
