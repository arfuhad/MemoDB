# Roadmap

## Phase 1 — Semantic Capture & Retrieval (current)

**Bet:** retrieve-by-meaning over my own text is useful enough to return to.
**Scope:** text only, desktop + mobile clients, local embeddings, hybrid retrieval.

### Built and statically verified
- Backend: capture / search / documents / health / rebuild endpoints; bearer auth.
- Schema: `documents` + `chunks vector(768)` with HNSW + FTS; `user_id` everywhere.
- Services: vault IO (files = truth), deterministic chunker, embedding interface
  (Ollama + API fallback), indexer (incremental + rebuild), hybrid retrieval (RRF).
- Flutter client: capture, search, document screens; API client; health indicator.
- Ops: docker-compose (pgvector + backend), Dockerfile, dependency-free `seed.py`.
- Checks done here: every module compiles; chunker/snippet/overlap/encoding logic tested.

### Runs on the developer machine (not in the build sandbox)
- `flutter create .` to generate platform runners (`macos/`, `android/`, `ios/`),
  then `flutter pub get` / `flutter run`.
- `pip install -e ".[dev]" && pytest` for the full backend suite.
- `dart analyze` for the client.
- End-to-end: `ollama serve` + `docker compose up` + `python backend/scripts/seed.py`.

### Definition of done (P1)
A meaning-query (e.g. "how do I remember things long term") surfaces the right notes
without sharing their words, **and** the rebuild-from-files parity check passes.
Then — and only then — watch whether you actually feed the vault for ~2 weeks before
starting P2.

## Phase 2 — Make it stick & go multimodal (gated on P1)
- Voice → transcript (Whisper), image caption/CLIP, video-link transcripts.
- Mobile as a first-class client against a cloud-hosted, always-on backend.
- Resurfacing / review prompts; "on this day" / random note.
- Cross-device sync of the **vault** (git or Syncthing); each device rebuilds its own
  index — text-level conflict resolution, never a DB merge.
- Real per-user auth replacing the static bearer token.

## Phase 3 — Depth (gated on P2)
- Index notes / MOCs; AI summarize/suggest over your corpus; templates; richer media.

## Deferred / explicitly not now
Graph view, proactive AI suggestions, agentic workflows, collaboration/multi-user,
people-memory. Revisit only with new evidence (see the original cut log).
