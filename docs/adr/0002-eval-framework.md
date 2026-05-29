# ADR-0002: Evaluation Framework — Arcana Eval + Tribunal

**Status:** Accepted (with licensing caveat on Tribunal)  
**Date:** 2026-05-24

---

## Context

The PRD (§14) defines two distinct eval tracks that require different fixes when they fail:

- **Retrieval quality:** Did the right chunks surface? Fix chunking, embeddings, or query formulation.
- **Answer quality:** Was the advice correct given retrieved context? Fix the prompt or model.

The PRD also defines a third eval surface that is easy to overlook:

- **Structured output validity:** Do `audit-repo`, `review-collector`, and `review-alerts` produce schema-correct JSON findings? Broken schemas are silent failures that LLM judges miss and that break agent consumers downstream.

George Guimarães (Arcana's author) also maintains **Tribunal**, an Elixir LLM eval framework. Both libraries are Elixir-native, maintained by the same author, and designed to compose.

---

## Decision

Use **Arcana's built-in eval system** for retrieval quality and **Tribunal** for answer quality and structured output validity. The two tools map cleanly to the PRD's three eval surfaces.

### Ownership by eval surface

| Surface | Tool | What is measured |
|---|---|---|
| Retrieval quality | Arcana eval | MRR, Recall@K, Precision@K, Hit@K; correct sources surfaced per `source_requirements` and `required_recall` |
| Answer quality (prose) | Tribunal LLM-as-judge | Faithfulness, `expected_topics` coverage, `must_not_include` violations |
| Structured output (JSON) | Tribunal deterministic | JSON schema validity, required fields present, severity enum values, finding ID format |

### CI mode split

Tribunal runs in two modes; both are used with distinct scope:

| Mode | Trigger | Scope |
|---|---|---|
| **ExUnit** (hard fail) | Every CI run | Schema validity, `must_not_include` violations, banned source recommendations (e.g. CC BY-NC-ND content must never appear in citations) |
| **Mix eval tasks** (threshold-based) | PR merge and scheduled | PRD §13 quality metrics: ≥80% answers correct, ≥90% with citations, <10% unsupported claims |

This answers the PRD §18 open question "How strict should CI mode be by default?" — strict on correctness invariants, threshold-based on quality metrics.

### Test case generation strategy

Arcana's synthetic test case generator (samples chunks → LLM generates retrieval questions) is appropriate for bootstrapping retrieval evals but is **not sufficient** for the PRD's high-value eval categories. Concept-selection, alert quality, and cardinality judgment questions require handwritten cases with explicit `expected_topics` and `must_not_include` fields.

| Category | Generation approach |
|---|---|
| Retrieval recall ("Which chunks surface for X?") | Arcana synthetic — acceptable |
| Concept selection ("metric vs span event?") | Handwritten — required |
| Alert quality ("Is this alert actionable?") | Handwritten — required |
| Cardinality judgment | Handwritten — required |
| Structured output schema | Tribunal deterministic — automated |

Target: 100–200 total cases (PRD §14), with synthetic covering retrieval bootstrapping and handwritten covering all judgment categories.

### Deferred: red team / adversarial testing

Tribunal supports red team attack generation (encoding, injection, jailbreak). This is out of scope for the MVP eval plan. Mark as available-but-deferred; do not invest in it before the quality metrics in PRD §13 are met.

---

## Tribunal licensing caveat

As of 2026-05-24, **Tribunal has no LICENSE file**. GitHub reports `null` for its SPDX identifier. No license = all rights reserved by default.

Mitigations, in order of preference:

1. **Open a GitHub issue asking the author to add a license.** The repo is actively maintained (last push: 2026-05-13) and has 90 stars; this is a reasonable ask.
2. **Limit Tribunal to the eval directory only.** Evals are not distributed to end users (they live in the backend repo and never ship in the CLI binary or Arcana-based API). This limits the scope of the unlicensed dependency.
3. **Fallback plan:** If no license is added, the Tribunal-style deterministic assertions and LLM-as-judge patterns can be reimplemented in ~200 lines of ExUnit helpers. The concepts are standard; the library is convenient, not irreplaceable.

Do not mark this ADR fully resolved until Tribunal's license status is confirmed.

---

## Consequences

**Positive:**

- Both tools are Elixir-native and maintained by the same author as Arcana — low integration friction.
- Three eval surfaces are explicitly owned rather than conflated.
- CI mode split answers a PRD open question concretely.
- Handwritten-vs-synthetic distinction prevents over-relying on LLM-generated evals for judgment categories.
- Eval work is scoped to the backend repo and does not affect CLI distribution.

**Negative / trade-offs:**

- Tribunal's unlicensed status introduces a dependency risk. Mitigation above.
- Handwritten eval cases for judgment categories are labor-intensive. The 20-case MVP target (Milestone 1) is achievable; 100–200 full-set cases are a sustained effort.
- LLM-as-judge evals (Tribunal) require an LLM call per eval case — adds latency and cost to CI. Mitigate by running threshold-based evals on PR merge only, not on every commit.

---

## Related

- PRD: `PRD O11y Advisor MVP.md` §13 (Quality Metrics), §14 (Evaluation Plan)
- ADR-0001: `docs/adr/0001-polyglot-architecture.md` — Elixir backend context
- Arcana evaluation guide: <https://github.com/georgeguimaraes/arcana/blob/main/guides/evaluation.md>
- Tribunal: <https://github.com/georgeguimaraes/tribunal>
