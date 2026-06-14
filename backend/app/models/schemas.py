from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class CaptureRequest(BaseModel):
    text: str = Field(min_length=1, description="Raw text to capture")
    title: str | None = Field(default=None, description="Optional title; derived if absent")
    tags: list[str] = Field(default_factory=list)


class TitleSuggestRequest(BaseModel):
    text: str = Field(min_length=1)


class TitleSuggestResponse(BaseModel):
    title: str


class UpdateRequest(BaseModel):
    text: str = Field(min_length=1)
    title: str | None = None
    tags: list[str] = Field(default_factory=list)


class DocumentSummary(BaseModel):
    id: str
    title: str
    vault_path: str
    created_at: datetime
    updated_at: datetime
    tags: list[str] = Field(default_factory=list)
    preview: str = ""


class Document(DocumentSummary):
    body_text: str
    frontmatter: dict


class SearchHit(BaseModel):
    document_id: str
    title: str
    snippet: str
    score: float = Field(description="Fused rank score (higher = better)")
    vector_rank: int | None = None
    keyword_rank: int | None = None


class SearchResponse(BaseModel):
    query: str
    hits: list[SearchHit]


class HealthResponse(BaseModel):
    status: str
    db: bool
    embedder: str
    embed_model: str
    embed_dim: int
    documents: int | None = None


class RebuildResponse(BaseModel):
    documents_indexed: int
    chunks_embedded: int

class AppConfig(BaseModel):
    title_provider: str
    title_model: str
    title_api_url: str
    title_api_key: str
    embedder: str
    api_embed_url: str
    api_embed_key: str
    api_embed_model: str
    ollama_url: str

class AppConfigUpdate(BaseModel):
    title_provider: str | None = None
    title_model: str | None = None
    title_api_url: str | None = None
    title_api_key: str | None = None
    embedder: str | None = None
    api_embed_url: str | None = None
    api_embed_key: str | None = None
    api_embed_model: str | None = None
    ollama_url: str | None = None
