"""Vault IO — markdown files are the source of truth.

Every captured artifact is a `.md` file with YAML frontmatter. Nothing about a
document is authoritative unless it lives here; Postgres is rebuilt from these.
"""
from __future__ import annotations

import hashlib
import re
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

import frontmatter

INBOX_DIR = "00-inbox"


@dataclass
class VaultDocument:
    id: str
    title: str
    body: str
    tags: list[str] = field(default_factory=list)
    kind: str = "text"
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    vault_path: str = ""

    @property
    def content_hash(self) -> str:
        return hashlib.sha256(self.body.encode("utf-8")).hexdigest()

    @property
    def frontmatter(self) -> dict:
        return {
            "id": self.id,
            "title": self.title,
            "kind": self.kind,
            "tags": self.tags,
            "created": self.created_at.isoformat(),
            "updated": self.updated_at.isoformat(),
        }


def _slugify(text: str, max_len: int = 60) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return (slug[:max_len].strip("-")) or "note"


def _derive_title(text: str) -> str:
    first = text.strip().splitlines()[0] if text.strip() else "Untitled"
    return first[:80].strip() or "Untitled"


class Vault:
    def __init__(self, root: Path):
        self.root = Path(root)
        (self.root / INBOX_DIR).mkdir(parents=True, exist_ok=True)

    # ── write (truth) ─────────────────────────────────────────────────────────
    def create_text(self, text: str, title: str | None = None,
                    tags: list[str] | None = None) -> VaultDocument:
        doc_id = str(uuid.uuid4())
        title = title or _derive_title(text)
        now = datetime.now(timezone.utc)
        doc = VaultDocument(
            id=doc_id, title=title, body=text, tags=tags or [],
            created_at=now, updated_at=now,
            vault_path=f"{INBOX_DIR}/{now:%Y%m%d-%H%M%S}-{_slugify(title)}.md",
        )
        self._write(doc)
        return doc

    def _write(self, doc: VaultDocument) -> None:
        post = frontmatter.Post(doc.body, **doc.frontmatter)
        path = self.root / doc.vault_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(frontmatter.dumps(post).encode("utf-8"))

    def update(
        self,
        vault_path: str,
        text: str,
        title: str | None = None,
        tags: list[str] | None = None,
    ) -> VaultDocument:
        doc = self.read(vault_path)
        doc.body = text
        doc.title = title or _derive_title(text)
        if tags is not None:
            doc.tags = tags
        doc.updated_at = datetime.now(timezone.utc)
        self._write(doc)
        return doc

    def delete(self, vault_path: str) -> None:
        path = self.root / vault_path
        if path.exists():
            path.unlink()

    # ── read / scan (for rebuild & reconcile) ─────────────────────────────────
    def read(self, vault_path: str) -> VaultDocument:
        return self._parse(self.root / vault_path, vault_path)

    def scan(self):
        for path in sorted(self.root.rglob("*.md")):
            rel = path.relative_to(self.root).as_posix()
            yield self._parse(path, rel)

    def _parse(self, path: Path, rel: str) -> VaultDocument:
        post = frontmatter.load(str(path))
        meta = post.metadata
        return VaultDocument(
            id=str(meta.get("id") or uuid.uuid4()),
            title=str(meta.get("title") or _derive_title(post.content)),
            body=post.content,
            tags=list(meta.get("tags") or []),
            kind=str(meta.get("kind") or "text"),
            created_at=_parse_dt(meta.get("created")),
            updated_at=_parse_dt(meta.get("updated")),
            vault_path=rel,
        )


def _parse_dt(value) -> datetime:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, str):
        try:
            dt = datetime.fromisoformat(value)
            return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
        except ValueError:
            pass
    return datetime.now(timezone.utc)
