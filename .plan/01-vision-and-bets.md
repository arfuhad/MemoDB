# Vision & Bets

## Vision

A personal knowledge management system that eventually ingests *everything* —
text, voice, images, video links — processes it, and makes it retrievable by
**meaning** rather than by remembering the exact words. Personal, local-first,
running across desktop, mobile, and (later) web from a single Flutter codebase.
The backend runs on the developer's Mac in P1; a small cloud host is the option
for always-on access later.

## The discipline: one bet per phase

PKM tools die from non-use, not from missing features. So each phase exists to
de-risk exactly one thing. Don't build the next phase until the current bet
holds.

### P1 bet — *is retrieve-by-meaning over my own text actually useful?*

P1 is **text-only**. Type text; later, a meaning-based search surfaces it
without sharing its words. If that doesn't feel valuable on your own corpus, no
amount of voice/image/video ingestion will save it.

> ⚠️ A known tension: the original Build Plan bet on a *different* risk — whether
> you'd form the daily capture habit at all. We consciously switched to the
> retrieval bet (see decision **D0**). Retrieval quality is the more tractable
> risk; the habit risk is still unproven and is the most likely way this dies.
> Mitigation: after retrieval is good, watch whether you actually feed the vault
> for two weeks before starting P2.

### P2 bet — *does it stick, and does it work everywhere I am?*

Multimodal ingestion (voice→transcript, image caption/CLIP, video transcripts),
mobile as a first-class client against a cloud-hosted backend, resurfacing/review,
and cross-device sync of the vault. Only if P1 retrieval proved its worth.

### P3 bet — *depth* — MOCs, AI over your corpus, templates, richer media.

## Non-negotiable principles

1. **Files are the source of truth.** Markdown + blobs on disk; the database is a
   rebuildable index. This is the anti-lock-in and anti-merge-hell guarantee.
2. **Clients never touch the database.** A backend API is the security boundary.
3. **Local-first.** Local embeddings by default; the network is optional.
4. **Prove before you expand.** Modalities and features are added only after the
   current bet holds.
