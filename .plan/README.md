# PKM — Project Plan

The canonical planning home for the PKM project. This folder holds the *why* and
the *when*; the *how* (architecture) lives in `../docs/ADR-0001-architecture.md`,
which these docs reference rather than copy — one source per fact.

## Contents

| File | What it covers |
|---|---|
| [`01-vision-and-bets.md`](01-vision-and-bets.md) | The product vision and the specific risk each phase de-risks |
| [`02-decision-log.md`](02-decision-log.md) | Every decision made, the options, the rationale, and the dissent |
| [`03-architecture.md`](03-architecture.md) | Architecture summary + pointer to the ADR |
| [`04-data-model.md`](04-data-model.md) | Vault layout, frontmatter contract, DB schema notes |
| [`05-api-and-app-flow.md`](05-api-and-app-flow.md) | API surface and the end-to-end user flow |
| [`06-roadmap.md`](06-roadmap.md) | Phases, what's built, what's next, definition of done |
| [`07-risks-and-open-questions.md`](07-risks-and-open-questions.md) | Live risks, deferred items, open questions |

## Relationship to the other planning docs

- **This folder (`.plan/`)** — narrative: vision, bets, decisions, roadmap, risks.
- **`../docs/ADR-0001-architecture.md`** — the architecture decision record (source of truth for *how* it's built).
- **The two prior docs** (`PKM_Build_Plan.md`, `PKM_Feature_Catalog.md`) — the
  original retention-first outline and the feature menu. The build plan's P1 gate
  (the daily capture loop) was consciously **superseded** by the semantic-retrieval
  bet; see `02-decision-log.md` entry D0 for why and what that trades.

## Status (P1)

Backend, schema, and Flutter client are scaffolded and statically verified.
Full test run, `dart analyze`, and the end-to-end flow run on the developer's
machine. See `06-roadmap.md` for the exact state and next actions.
