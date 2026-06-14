import pytest

from app.services.embeddings.base import Embedder, EmbeddingError


class FakeEmbedder(Embedder):
    name = "fake"

    def __init__(self, dim, out_dim):
        super().__init__("fake-model", dim)
        self._out_dim = out_dim

    async def embed(self, texts):
        return self._check_dim([[0.1] * self._out_dim for _ in texts])


async def test_correct_dim_passes():
    emb = FakeEmbedder(dim=768, out_dim=768)
    vecs = await emb.embed(["a", "b"])
    assert len(vecs) == 2 and all(len(v) == 768 for v in vecs)


async def test_wrong_dim_raises():
    emb = FakeEmbedder(dim=768, out_dim=512)
    with pytest.raises(EmbeddingError):
        await emb.embed(["a"])


async def test_health_true_when_embed_works():
    assert await FakeEmbedder(768, 768).health() is True
