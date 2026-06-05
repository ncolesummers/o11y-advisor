# ADR-0005: Embedding Model

**Status:** Accepted
**Date:** 2026-06-05

---

## Context

The MVP retrieval store uses PostgreSQL + pgvector through Arcana. The embedding model fixes the vector column dimension, so changing models later requires a schema migration and re-embedding the corpus.

The PRD previously named OpenAI `text-embedding-3-small`, but Arcana's local embedder supports Hugging Face models up to 1024 dimensions. Keeping embeddings inside Arcana's supported local path avoids a second provider dependency for ingestion and keeps tests able to use deterministic fake embeddings.

Available Arcana local model options for MVP:

| Model | Dimensions | Size | Tradeoff |
| --- | ---: | ---: | --- |
| `BAAI/bge-small-en-v1.5` | 384 | 133MB | Default, fastest BGE option |
| `BAAI/bge-base-en-v1.5` | 768 | 438MB | Better quality without large-model memory cost |
| `BAAI/bge-large-en-v1.5` | 1024 | 1.3GB | Best BGE quality, highest memory cost |
| `intfloat/e5-base-v2` | 768 | 438MB | Similar size, requires query/document prefixes |
| `thenlper/gte-small` | 384 | 67MB | Smallest supported option |

---

## Decision

Use `BAAI/bge-base-en-v1.5` for MVP embeddings.

Configure Arcana with the local embedder:

```elixir
config :arcana, embedder: {:local, model: "BAAI/bge-base-en-v1.5"}
```

Set `arcana_chunks.embedding` to `vector(768)`.

---

## Consequences

**Positive:**

- Better retrieval signal than 384-dimensional defaults while staying well below the memory cost of 1024-dimensional models.
- Embeddings stay on Arcana's supported local path.
- The embedding dimension is explicit and testable in the pgvector schema.

**Negative / trade-offs:**

- Local embedding requires loading a 438MB model in non-test environments.
- If retrieval evals underperform, moving to `BAAI/bge-large-en-v1.5` requires a migration to `vector(1024)` and re-embedding the corpus.
- Existing 384-dimensional chunks, if any, must be discarded or re-embedded.

---

## Related

- PRD: `PRD O11y Advisor MVP.md` §15 and §18
- ADR-0001: `docs/adr/0001-polyglot-architecture.md` — hosted backend with shared PostgreSQL + pgvector
- ADR-0004: `docs/adr/0004-llm-provider.md` — inference provider decision excludes embeddings
- GitHub issue: #18
