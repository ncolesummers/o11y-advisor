# ADR-0004: LLM Inference Provider — req_llm with Gemini 3.5 Flash for Development

**Status:** Accepted  
**Date:** 2026-06-02

---

## Context

The Elixir backend needs to call an LLM for two distinct purposes:

1. **Answer generation** — Arcana's agentic RAG loop calls an LLM to synthesize source-grounded answers for the `ask` pipeline.
2. **LLM-as-judge evaluation** — Tribunal calls an LLM to evaluate faithfulness, `expected_topics` coverage, and `must_not_include` violations (ADR-0002).

Both Arcana and Tribunal are built on **req_llm** (agentjido/req_llm), a provider-agnostic Elixir LLM library that normalizes requests and responses across 21+ providers (Anthropic, Google Gemini, OpenAI, Bedrock, and others) behind a single interface. req_llm resolves providers via a model-string like `"google:gemini-3.5-flash"` and picks up API keys from environment variables, application config, or `.env` files.

No provider was previously named in project documentation. CONTRIBUTING.md implicitly assumed Anthropic by referencing `ANTHROPIC_API_KEY` in two places. That assumption was never an explicit decision.

**Scope of this decision — inference only.** Embeddings are a separate concern: the embedding model is coupled to the pgvector dimension schema, and changing embedding providers requires re-embedding the entire corpus. That tradeoff is not addressed here.

**Cost constraint.** Gemini 3.5 Flash (GA since Google I/O, May 2026; model ID `gemini-3.5-flash`) delivers frontier-class performance at significantly lower cost than current Anthropic and OpenAI offerings. For a side project with low call volume, cost control during development is a first-class concern.

---

## Decision

**Use req_llm as the single LLM inference interface. No new adapter layer is needed.**

Both Arcana and Tribunal already depend on req_llm transitively. Adding a parallel Elixir `behaviour` + per-provider adapters would duplicate an abstraction that already exists. The provider is fully swappable at the call site by changing the model string; no code changes are required to switch providers.

**Default development model: `"google:gemini-3.5-flash"`.** Configure via `GOOGLE_API_KEY` environment variable. Production configuration can override this via `runtime.exs` or Fly.io secrets without code changes.

**Inference and judge are independently configurable.** The answer pipeline (Arcana) and the Tribunal judge calls can use different model strings if quality tradeoffs require it. They share the same req_llm interface but are separate call sites.

### Configuration convention

| Use | Model string | Env var | Environment |
|---|---|---|---|
| Answer generation | `"google:gemini-3.5-flash"` | `GOOGLE_API_KEY` | Dev default |
| LLM-as-judge (Tribunal) | `"google:gemini-3.5-flash"` | `GOOGLE_API_KEY` | Dev default |
| Production | Override in `runtime.exs` | Per-provider key | Fly.io secrets |

Model strings follow req_llm's `"provider:model-id"` format. Exact IDs should be verified against [LLMDB.xyz](https://llmdb.xyz) before pinning in config.

---

## Open Question

**Should the LLM-as-judge use the same cheap model as answer generation?**

A weaker judge produces weaker eval signal; a stronger judge costs more. Starting assumption: use Gemini 3.5 Flash for both in development, because there is no quality baseline yet against which to measure signal degradation. Revisit when the first 20-case eval run (#20) establishes a baseline — compare Gemini Flash judge verdicts against a sample with a frontier model to measure divergence.

---

## Consequences

**Positive:**

- No new abstraction to build or maintain — req_llm is already a transitive dependency.
- Provider swap is a model string change + key swap. No code change required.
- Gemini 3.5 Flash is GA, designed for agents, and 4× faster output than current frontier models.
- Inference and judge can diverge independently when quality data justifies it.

**Negative / trade-offs:**

- Using Gemini Flash as judge may weaken eval signal relative to a frontier model. Acceptable before baselines exist; the open question above gates reassessment.
- `GOOGLE_API_KEY` replaces the previously assumed `ANTHROPIC_API_KEY`. CONTRIBUTING.md and local dev setup documentation must be updated.
- If the judge model is changed after baselines are established, metric drift may appear as apparent quality regression. Document any judge model change as a known cause of metric shift.

---

## Related

- ADR-0002: `docs/adr/0002-eval-framework.md` — Tribunal LLM-as-judge calls; judge model is configured per this ADR
- ADR-0001: `docs/adr/0001-polyglot-architecture.md` — Elixir backend; all LLM inference calls originate here
- req_llm library: <https://github.com/agentjido/req_llm>
- Gemini 3.5 Flash model docs: <https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash>
- LLMDB model registry: <https://llmdb.xyz>
- Unblocks: #21 (ask answering pipeline), #15 (eval harness — LLM-as-judge tier)