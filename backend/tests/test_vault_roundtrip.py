from pathlib import Path

from app.services.vault import Vault


def test_create_and_scan_roundtrip(tmp_path: Path):
    vault = Vault(tmp_path)
    doc = vault.create_text("First line title\n\nBody content about memory.",
                            tags=["learning"])

    # File written as the source of truth.
    assert (tmp_path / doc.vault_path).exists()

    # Scanning the vault recovers the same logical document (proves rebuildability).
    scanned = list(vault.scan())
    assert len(scanned) == 1
    s = scanned[0]
    assert s.id == doc.id
    assert s.title == doc.title
    assert "memory" in s.body
    assert s.tags == ["learning"]
    assert s.content_hash == doc.content_hash


def test_title_derived_from_first_line(tmp_path: Path):
    vault = Vault(tmp_path)
    doc = vault.create_text("Spaced repetition beats cramming")
    assert doc.title.startswith("Spaced repetition")
