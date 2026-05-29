# ADR-0003: Ingestion Timing & Semconv Version-Pin Enforcement

**Status:** Accepted  
**Date:** 2026-05-29

---

## Context

Two PRD §18 open questions block the ingestion stories (#16, #17, #18). They are cheap to resolve now and expensive to retrofit once the pipeline exists:

1. Should source ingestion happen at **build time, install time, or on demand**?
2. Should OTel semconv version pinning be enforced at **ingestion time, query time, or both**?

Constraints already fixed by prior decisions:

- The knowledge base is **shared hosted infrastructure** on Fly.io — PostgreSQL + pgvector. Users do not run their own copy; they install only the Go CLI, which carries no KB. (ADR-0001)
- The default ingestion path is **GitHub repo source** at a pinned ref; every source registry entry carries `{ repo, path_glob, license, version_pin }`. (PRD §8)
- Every ingested document stores source metadata including `version` and `retrieved_at`. (PRD §8)
- **Version-aware retrieval is required for OTel semantic conventions** (versioned per-signal; mixed-version retrieval produces incorrect attribute-name advice) and **best-effort for other sources**. (PRD §9)
- OTel ships monthly; semconv is versioned per-signal. Docs drift is a high risk for semconv, mitigated by required version pins and a CI refresh job. (PRD §16)

A throwaway prototype (`mix spike.ingest`, deleted with #16/#17) fetched a single pinned semconv file (`semantic-conventions@v1.29.0/docs/http/http-spans.md`) and stamped the pinned ref onto the document's `version` field, with no DB or embeddings. It confirmed the on-demand-job model and ingestion-time pinning are trivial to realize over the GitHub raw path.

---

## Decision

### Q1 — Ingestion timing: a decoupled backend job, triggered on demand and on a schedule

- **Install time — not applicable.** The KB is shared hosted infrastructure (ADR-0001). Users install the Go CLI, which holds no corpus, so there is no per-user install to ingest into.
- **Build time — rejected.** pgvector data lives in managed Postgres, *not* in the app release image, so a build or deploy cannot carry the corpus. Coupling corpus refresh to app redeploys also fights the monthly OTel cadence (PRD §16), and ingestion is slow and expensive (GitHub fetch + embeddings) so it must not block application boot.
- **On demand — chosen.** Ingestion runs as a **backend-invoked job** (a Mix task for MVP), triggerable manually and on a schedule. The scheduled trigger is the PRD §16 "CI refresh job". This is the smallest model that satisfies ADR-0001's "shared hosted KB, users don't run their own copy": ingestion writes to the shared Postgres out of band from request serving and from deploys.

### Q2 — Semconv version pinning: enforce at **both** ingestion and query time, with split roles

- **Ingestion-time pinning applies to all sources.** Each source is fetched at its registry `version_pin` ref (reproducible ingestion), and the resolved ref is stamped onto every document's — and therefore every chunk's — `version` metadata (PRD §8). This is needed for citations regardless of retrieval, and it guarantees no unpinned/`main` content silently enters the store.
- **Query-time version enforcement is required for semconv only; best-effort elsewhere** (PRD §9). Mechanism: retrieval restricts semconv chunks to the configured **active** pinned version, so a single answer never mixes semconv versions (mixed-version retrieval yields wrong attribute names). For non-semconv sources, version is best-effort metadata and is not filtered on.

These roles are complementary, not redundant: ingestion is where the pin is *applied and recorded*; query is where the pin is *honored* so answers stay version-coherent.

### MVP scope

Store **exactly one** pinned semconv version for MVP, but implement the query-time version filter **from day one**. With a single stored version the filter is a no-op today; it becomes load-bearing the instant a second pin lands. Per the spike's own rationale — *cheap to resolve now, expensive to retrofit* — the filter is cheap insurance and the `version` field is populated from the first ingested document.

---

## Consequences

**Positive:**

- Corpus refresh is independent of app deploys — semconv pin bumps and the §16 CI refresh job ship corpus changes without a redeploy.
- Ingestion-time pinning gives reproducible ingestion and correct citations for free; the `version` stamp is the single value query-time filtering keys on.
- The semconv version invariant is explicit and testable from MVP, so the eventual multi-version state is a non-breaking change rather than a retrofit.
- The on-demand job model is small: a Mix task today, a scheduled invocation later — no new runtime surface.

**Negative / trade-offs:**

- A query-time filter that is a no-op at MVP is carried before it is strictly needed. Justified by the low cost and the high retrofit cost.
- "On demand" means the corpus can be stale between refreshes; freshness is bounded by the schedule cadence, not by deploys. Acceptable given monthly OTel cadence and stored `retrieved_at`.
- Single stored semconv version means questions implicitly target the active pin; cross-version "what changed" questions are out of scope until multiple pins are stored.

---

## Related

- PRD: `PRD O11y Advisor MVP.md` §8 (Ingestion Strategy & Source Metadata), §9 (Retrieval Requirements — version-aware retrieval), §16 (Risks — docs drift), §18 (Open Questions)
- ADR-0001: `docs/adr/0001-polyglot-architecture.md` — shared hosted KB; users do not run their own copy
- Unblocks: #16 (source registry), #17 (GitHub fetch + parse), #18 (chunk + embed + store)
- Prototype: `backend/lib/mix/tasks/spike.ingest.ex` (throwaway; delete with #16/#17)
