"""Async Postgres pool.

pgvector values are passed as text literals (e.g. "[1,2,3]") with an explicit
`::vector` cast at each call site. This avoids relying on a per-connection type
codec, which would race the extension-creation migration at startup."""
from __future__ import annotations

from collections.abc import Iterable
from pathlib import Path

import asyncpg

from .config import Settings

_pool: asyncpg.Pool | None = None


def to_pgvector(vec: Iterable[float]) -> str:
    """Encode a vector as the text form pgvector accepts: "[1.0,2.0,3.0]"."""
    return "[" + ",".join(repr(float(x)) for x in vec) + "]"


async def connect(settings: Settings) -> asyncpg.Pool:
    global _pool
    if _pool is None:
        _pool = await asyncpg.create_pool(
            settings.database_url,
            min_size=1,
            max_size=10,
        )
    return _pool


async def disconnect() -> None:
    global _pool
    if _pool is not None:
        await _pool.close()
        _pool = None


def pool() -> asyncpg.Pool:
    if _pool is None:
        raise RuntimeError("DB pool not initialised")
    return _pool


async def run_migrations(settings: Settings) -> None:
    """Apply migrations idempotently (the SQL uses IF NOT EXISTS throughout).
    Compose also runs these via docker-entrypoint-initdb.d, but this makes the
    direct-uvicorn path self-sufficient."""
    migrations_dir = Path(__file__).resolve().parent.parent / "migrations"
    async with pool().acquire() as conn:
        for sql_file in sorted(migrations_dir.glob("*.sql")):
            await conn.execute(sql_file.read_text())
