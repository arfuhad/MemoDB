# Decision Log

Each entry: the decision, the options weighed, the rationale, and the dissent or
risk recorded at the time. Decisions are not reopened without new evidence.

---

## D0 — P1 proves semantic retrieval, not the capture habit
**Decision:** Make meaning-based retrieval the P1 hypothesis. P1 is text-only.
**Supersedes:** `PKM_Build_Plan.md`, which made the daily capture loop the P1 gate
and marked semantic search as P2 ("high value, but only once corpus is worth searching").
**Rationale:** The product's core value proposition *is* a semantic memory. Validating
keyword-search-and-habit first would validate the wrong thing.
**Dissent on record:** Retrieval quality is the *easier, solved* risk; retention
(will you keep feeding it) is the *harder, unsolved* one. Spending P1 on retrieval
means the harder risk stays unproven. Accepted knowingly; mitigated by watching
real usage after retrieval works.

## D1 — Stack: Flutter clients + FastAPI backend + Postgres/pgvector
**Decision:** Flutter for desktop + mobile (web later); FastAPI (Python) backend;
Postgres 16 with pgvector.
**Rationale:** Flutter = one codebase across three targets; mobile capture is where
retention is actually won. FastAPI because the whole AI roadmap (embeddings, Whisper,
CLIP, vector ops) is Python-native and pgvector tooling there is mature.
**Cost accepted:** Dart + Python + the existing Node apps = three languages.

## D2 — A backend API sits in front of the database
**Decision:** Clients speak HTTPS + bearer token to the backend; they never hold DB
credentials or touch Postgres directly.
**Rationale:** A client with DB credentials is a security hole (no auth boundary,
logic in the UI, a leaked build exposes the whole corpus). The backend owns auth,
business logic, the vault, embeddings, and the DB.
**Consequence:** This is what makes mobile viable in P1 — the phone talks to the API.

## D3 — Source of truth = files on disk (hybrid); Postgres is derived
**Decision:** Markdown (text) + blobs (future) on disk are authoritative. Postgres +
pgvector is a rebuildable index (metadata, extracted text, embeddings).
**Rationale:** Keeps portability and no lock-in, and — critically — means the DB is
never the thing you sync or merge. Offline conflict resolution becomes a *text-file*
merge in P2, not a database merge. `rebuild` reconstructs the index any time.
**Invariant:** every write is **file first, index second**.

## D4 — Embeddings: local now, API fallback, dimension pinned at 768
**Decision:** Default to Ollama `nomic-embed-text` (local, 768-dim). An OpenAI-compatible
`ApiEmbedder` (with `dimensions=768`) sits behind the same interface. Dimension is
pinned at 768 to match the `vector(768)` column.
**Rationale:** Local fits the local-first ethos — private, no per-item cost. The
fallback covers cases where local is impractical (notably: a phone can't run Ollama).
**Guard:** `embedding_model` is stored per chunk so a model/dimension change is
detected and triggers a re-embed rather than silent corruption.

## D5 — Retrieval is hybrid (vector + FTS, reciprocal-rank fusion)
**Decision:** Fuse cosine vector similarity (HNSW) with Postgres full-text search via
RRF. Best chunk per document; one hit per document.
**Rationale:** Semantic is the bet, but FTS fusion is nearly free and measurably
improves results, so it ships as support — not as a separate feature.

## D6 — Clients in P1: desktop *and* mobile
**Decision:** Both Flutter clients ship in P1.
**Rationale:** Exercises the API on two platforms early and matches the full vision.
**Cost accepted:** The backend must be network-reachable for the phone — in P1 it
runs on the Mac (phone via LAN IP), so mobile works when the Mac is on and on the
same network. True always-on / off-network mobile needs a cloud host, which is a P2
option (containerized, so it's a config change, not a rewrite).

## D8 — No Raspberry Pi; Mac in P1, cloud later
**Decision:** Drop the Raspberry Pi as the always-on node. P1 hosts the backend on the
developer's Mac. When always-on / off-network mobile is wanted, deploy the containers
to a small cloud host (and, at that point, optionally use managed Postgres such as Neon).
**Rationale:** A dedicated home node adds hardware and ops for no P1 payoff; the Mac is
sufficient to prove the retrieval bet. Cloud is the cleaner always-on path when needed.
**Consequence:** In P1, mobile only reaches the backend when the Mac is running and on
the same LAN — acceptable for proving the bet, not for "use it anywhere."

## D7 — No standalone server beyond the API; in-process services
**Decision:** The FastAPI app embeds the data layer (vault IO, chunker, embedder,
indexer, retrieval). No additional microservices in P1.
**Rationale:** One deployable unit is enough for a single-user system; the service
interfaces leave room to split later (e.g., a separate embedding/indexing worker).

## Cut for P1 (from the original plan, deferred not deleted)
Tasks-in-notes, bidirectional links, PARA triage, daily notes, voice/image/video
ingestion, cross-device sync, and real per-user auth. These belong to P2+ and are
built only if the P1 bet holds.
