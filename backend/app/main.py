from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api.routes import api, public
from .config import get_settings
from .db import connect, disconnect, run_migrations
from .deps import init_services


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    await connect(settings)
    await run_migrations(settings)
    init_services(settings)
    yield
    await disconnect()


app = FastAPI(title="PKM Backend", version="0.1.0", lifespan=lifespan)

# Flutter desktop/mobile clients are first-party; allow them through.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(public)
app.include_router(api)
