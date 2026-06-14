from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# Stable id of the seeded local user (see migrations/001_init.sql).
LOCAL_USER_ID = "00000000-0000-0000-0000-000000000001"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="PKM_", env_file=".env", extra="ignore")

    database_url: str = "postgresql://pkm:pkm@localhost:5432/pkm"
    vault_dir: Path = Path("./vault")
    api_token: str = "dev-local-token-change-me"

    # Embeddings
    embedder: str = "ollama"            # "ollama" | "api"
    embed_model: str = "nomic-embed-text"
    embed_dim: int = 768               # PINNED — must match the vector(768) column
    ollama_url: str = "http://localhost:11434"

    # API fallback
    api_embed_url: str = "https://api.openai.com/v1/embeddings"
    api_embed_key: str = ""
    api_embed_model: str = "text-embedding-3-small"

    # Title generation (uses Ollama generate API; empty string = heuristic fallback only)
    title_model: str = "gemma4:latest"


@lru_cache
def get_settings() -> Settings:
    s = Settings()
    s.vault_dir = Path(s.vault_dir).expanduser()
    s.vault_dir.mkdir(parents=True, exist_ok=True)
    return s
