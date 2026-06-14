"""API-fallback embeddings (OpenAI-compatible). Requests `dimensions=dim` so the
returned vectors match the pinned 768 column. Used only when PKM_EMBEDDER=api."""
from __future__ import annotations

import httpx

from .base import Embedder, EmbeddingError


class ApiEmbedder(Embedder):
    name = "api"

    def __init__(self, model: str, dim: int, url: str, api_key: str):
        super().__init__(model, dim)
        self.url = url
        self.api_key = api_key

    async def embed(self, texts: list[str]) -> list[list[float]]:
        if not texts:
            return []
        if not self.api_key:
            raise EmbeddingError("PKM_API_EMBED_KEY is empty but embedder=api")
        payload = {"model": self.model, "input": texts, "dimensions": self.dim}
        headers = {"Authorization": f"Bearer {self.api_key}"}
        async with httpx.AsyncClient(timeout=60.0) as client:
            try:
                resp = await client.post(self.url, json=payload, headers=headers)
                resp.raise_for_status()
                data = resp.json()
            except httpx.HTTPError as exc:
                raise EmbeddingError(f"API embed request failed: {exc}") from exc
        items = sorted(data.get("data", []), key=lambda d: d.get("index", 0))
        vectors = [[float(x) for x in item["embedding"]] for item in items]
        if len(vectors) != len(texts):
            raise EmbeddingError("API returned a different count than requested")
        return self._check_dim(vectors)
