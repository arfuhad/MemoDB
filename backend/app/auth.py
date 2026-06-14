"""P1 auth: a single static bearer token (the security boundary that keeps DB
credentials out of clients). Real per-user auth is a later phase."""
from fastapi import Depends, Header, HTTPException, status

from .config import Settings, get_settings


async def require_token(
    authorization: str | None = Header(default=None),
    settings: Settings = Depends(get_settings),
) -> None:
    expected = f"Bearer {settings.api_token}"
    if authorization != expected:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )
