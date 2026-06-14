from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query

from ..auth import require_token
from ..config import LOCAL_USER_ID, Settings, get_settings
from ..db import pool
from ..deps import get_embedder, get_indexer, get_title_gen, get_vault
from ..models.schemas import (
    CaptureRequest,
    UpdateRequest,
    TitleSuggestRequest,
    TitleSuggestResponse,
    Document,
    DocumentSummary,
    HealthResponse,
    RebuildResponse,
    SearchHit,
    SearchResponse,
    AppConfig,
    AppConfigUpdate,
)
from ..services import retrieval

public = APIRouter()
api = APIRouter(dependencies=[Depends(require_token)])


@public.get("/health", response_model=HealthResponse)
async def health(settings: Settings = Depends(get_settings)) -> HealthResponse:
    db_ok = True
    doc_count: int | None = None
    try:
        async with pool().acquire() as conn:
            doc_count = await conn.fetchval(
                "SELECT count(*) FROM documents WHERE user_id=$1", LOCAL_USER_ID
            )
    except Exception:
        db_ok = False
    return HealthResponse(
        status="ok" if db_ok else "degraded",
        db=db_ok,
        embedder=settings.embedder,
        embed_model=settings.embed_model if settings.embedder == "ollama" else settings.api_embed_model,
        embed_dim=settings.embed_dim,
        documents=doc_count,
    )


@api.post("/suggest-title", response_model=TitleSuggestResponse)
async def suggest_title(req: TitleSuggestRequest) -> TitleSuggestResponse:
    title = await get_title_gen().suggest(req.text)
    return TitleSuggestResponse(title=title)


@api.post("/capture", response_model=DocumentSummary, status_code=201)
async def capture(req: CaptureRequest) -> DocumentSummary:
    # File first (truth), index second (derived).
    doc = get_vault().create_text(req.text, title=req.title, tags=req.tags)
    await get_indexer().index_document(doc)
    return DocumentSummary(
        id=doc.id, title=doc.title, vault_path=doc.vault_path,
        created_at=doc.created_at, updated_at=doc.updated_at,
        tags=doc.tags,
        preview=doc.body[:120].strip() if doc.body else "",
    )


@api.get("/documents", response_model=list[DocumentSummary])
async def list_documents(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[DocumentSummary]:
    import json as _json
    async with pool().acquire() as conn:
        rows = await conn.fetch(
            """SELECT id, title, vault_path, created_at, updated_at,
                      frontmatter, body_text
               FROM documents WHERE user_id=$1
               ORDER BY created_at DESC
               LIMIT $2 OFFSET $3""",
            LOCAL_USER_ID, limit, offset,
        )
    result = []
    for row in rows:
        fm = row["frontmatter"]
        fm = _json.loads(fm) if isinstance(fm, str) else dict(fm or {})
        body = row["body_text"] or ""
        result.append(DocumentSummary(
            id=str(row["id"]),
            title=row["title"],
            vault_path=row["vault_path"],
            created_at=row["created_at"],
            updated_at=row["updated_at"],
            tags=list(fm.get("tags") or []),
            preview=body[:120].strip(),
        ))
    return result


@api.get("/search", response_model=SearchResponse)
async def search(
    q: str = Query(min_length=1),
    limit: int = Query(default=10, ge=1, le=50),
) -> SearchResponse:
    hits = await retrieval.search(pool(), get_embedder(), q, limit=limit)
    return SearchResponse(
        query=q,
        hits=[SearchHit(**h) for h in hits],
    )


@api.get("/documents/{doc_id}", response_model=Document)
async def get_document(doc_id: str) -> Document:
    async with pool().acquire() as conn:
        row = await conn.fetchrow(
            """SELECT id, title, vault_path, body_text, frontmatter,
                      created_at, updated_at
               FROM documents WHERE id=$1 AND user_id=$2""",
            doc_id, LOCAL_USER_ID,
        )
    if row is None:
        raise HTTPException(status_code=404, detail="Document not found")
    import json
    fm = row["frontmatter"]
    fm = json.loads(fm) if isinstance(fm, str) else dict(fm)
    body = row["body_text"] or ""
    return Document(
        id=str(row["id"]), title=row["title"], vault_path=row["vault_path"],
        body_text=body, frontmatter=fm,
        tags=list(fm.get("tags") or []),
        preview=body[:120].strip(),
        created_at=row["created_at"], updated_at=row["updated_at"],
    )


@api.put("/documents/{doc_id}", response_model=DocumentSummary)
async def update_document(doc_id: str, req: UpdateRequest) -> DocumentSummary:
    async with pool().acquire() as conn:
        row = await conn.fetchrow(
            "SELECT vault_path FROM documents WHERE id=$1 AND user_id=$2",
            doc_id, LOCAL_USER_ID,
        )
    if row is None:
        raise HTTPException(status_code=404, detail="Document not found")
    doc = get_vault().update(row["vault_path"], req.text, title=req.title, tags=req.tags)
    await get_indexer().index_document(doc)
    return DocumentSummary(
        id=doc.id, title=doc.title, vault_path=doc.vault_path,
        created_at=doc.created_at, updated_at=doc.updated_at,
        tags=doc.tags,
        preview=doc.body[:120].strip() if doc.body else "",
    )


@api.delete("/documents/{doc_id}", status_code=204)
async def delete_document(doc_id: str) -> None:
    async with pool().acquire() as conn:
        row = await conn.fetchrow(
            "SELECT vault_path FROM documents WHERE id=$1 AND user_id=$2",
            doc_id, LOCAL_USER_ID,
        )
    if row is None:
        raise HTTPException(status_code=404, detail="Document not found")
    get_vault().delete(row["vault_path"])
    async with pool().acquire() as conn:
        await conn.execute(
            "DELETE FROM documents WHERE id=$1 AND user_id=$2",
            doc_id, LOCAL_USER_ID,
        )


@api.post("/admin/rebuild", response_model=RebuildResponse)
async def rebuild() -> RebuildResponse:
    docs, embedded = await get_indexer().rebuild()
    return RebuildResponse(documents_indexed=docs, chunks_embedded=embedded)


@api.get("/config", response_model=AppConfig)
async def get_app_config() -> AppConfig:
    s = get_settings()
    return AppConfig(
        title_provider=s.title_provider,
        title_model=s.title_model,
        title_api_url=s.title_api_url,
        title_api_key=s.title_api_key,
        embedder=s.embedder,
        api_embed_url=s.api_embed_url,
        api_embed_key=s.api_embed_key,
        api_embed_model=s.api_embed_model,
        ollama_url=s.ollama_url,
    )

@api.put("/config", response_model=AppConfig)
async def update_app_config(req: AppConfigUpdate) -> AppConfig:
    from pathlib import Path
    import json
    from ..deps import init_services
    from ..config import get_settings
    
    # Save updates to vault_dir/settings.json
    s = get_settings()
    settings_file = s.vault_dir / "settings.json"
    
    # Merge with existing overrides if any
    existing = {}
    if settings_file.exists():
        try:
            existing = json.loads(settings_file.read_text())
        except Exception:
            pass
            
    updates = req.model_dump(exclude_unset=True)
    for k, v in updates.items():
        existing[k] = v
        
    settings_file.write_text(json.dumps(existing, indent=2))
            
    get_settings.cache_clear()
    new_settings = get_settings()
    init_services(new_settings)
    
    return await get_app_config()
