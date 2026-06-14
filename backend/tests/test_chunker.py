from app.services.chunker import chunk_text, make_snippet


def test_short_text_is_single_chunk():
    chunks = chunk_text("just a few words here")
    assert len(chunks) == 1
    assert chunks[0].ord == 0


def test_long_text_splits_with_increasing_ord():
    big = " ".join(f"w{i}" for i in range(1000))
    chunks = chunk_text(big)
    assert len(chunks) > 1
    assert [c.ord for c in chunks] == list(range(len(chunks)))


def test_chunking_is_deterministic():
    big = " ".join(f"w{i}" for i in range(1000))
    a = [c.text_hash for c in chunk_text(big)]
    b = [c.text_hash for c in chunk_text(big)]
    assert a == b  # text_hash drives "re-embed only what changed"


def test_overlap_between_consecutive_chunks():
    big = " ".join(f"w{i}" for i in range(1000))
    chunks = chunk_text(big, words_per_chunk=100, overlap=20)
    tail = chunks[0].text.split()[-20:]
    head = chunks[1].text.split()[:20]
    assert tail == head


def test_empty_text_yields_no_chunks():
    assert chunk_text("   ") == []


def test_snippet_centers_on_query():
    text = " ".join(["filler"] * 50 + ["target"] + ["filler"] * 50)
    snip = make_snippet(text, "target")
    assert "target" in snip
