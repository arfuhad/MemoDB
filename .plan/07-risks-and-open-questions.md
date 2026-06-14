# Risks & Open Questions

## Live risks

### R1 — The habit risk is unproven (highest)
P1 de-risks retrieval *quality*, which is the tractable problem. Whether you actually
*capture daily* — the original Build Plan's gate — is untested. The most likely
failure mode is a beautiful semantic search over an almost-empty vault.
**Mitigation:** once retrieval is good, measure real personal usage for ~2 weeks
before building any P2 feature.

### R2 — Local embedding cost as the corpus and modalities grow
`nomic-embed-text` is fine on a Mac for text. Heavier models (Whisper/CLIP in P2) or a
large re-embed may strain a single machine.
**Mitigation:** the `EmbeddingService` interface already allows an API fallback per
modality, so heavy embeds can be offloaded while text stays local.

### R3 — Embedding model lock-in by dimension
The schema pins `vector(768)`. Switching to a model with a different dimension means a
migration + full re-embed.
**Mitigation:** `embedding_model` is stored per chunk so mismatches are detectable;
`rebuild()` re-embeds everything from the vault when the model changes.

### R4 — Mobile reachability (sharper now that there's no always-on node)
In P1 the backend lives on the Mac, so the phone only reaches it when the Mac is on and
on the same LAN — and the Mac's IP changes between networks. There is no "use it
anywhere" until a cloud host exists.
**Mitigation:** `API_BASE` is a build-time define; the containerized backend moves to a
cloud host without code changes. If mobile-anywhere matters sooner, promote the cloud
host (D8) from P2 into P1.

### R5 — Single static bearer token
P1 auth is one shared token — adequate for a single user on a LAN, not for exposure to
the internet.
**Mitigation:** do not expose the backend publicly in P1; replace with real auth in P2.

## Open questions

1. **Platform runners** — generate `macos/`/`android/`/`ios/` now via `flutter create .`
   over `app/`, or let the developer run it on the Mac? (Currently: developer runs it.)
2. **Always-on hosting** — if/when mobile needs to work away from home, which cloud
   host (a small VM vs. a container platform), and whether to move Postgres to managed
   Neon at the same time. Decide before mobile becomes primary.
3. **Chunking strategy** — current splitter is word-budgeted with overlap. Revisit if
   retrieval quality is weak on long notes (semantic/sentence-aware chunking).
4. **Re-ranking** — RRF is the P1 fusion. If precision needs a lift, consider a
   cross-encoder re-rank over the fused top-k (P2).
5. **Backup** — the vault is the only thing that matters. Define a backup cadence
   (the DB is rebuildable; the files are not).

## Decisions deliberately closed (don't reopen without new evidence)
Stack (Flutter + FastAPI + Postgres/pgvector), backend-as-security-boundary,
files-as-truth, local-first embeddings, hybrid retrieval, text-only P1. See
`02-decision-log.md`.
