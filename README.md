# o11y-advisor

A specialist observability advisor for developers and coding agents. Ask it how to instrument your code, which telemetry signals to use, how to write alert rules, or how to review an OpenTelemetry Collector config — and get source-grounded answers drawn from the o11y documentation corpus.

**Status:** Pre-alpha — architecture decided, implementation not started.

---

## What it does

o11y-advisor exposes a curated knowledge base (OpenTelemetry, Prometheus, Grafana, Loki, Tempo, SRE practices) through three surfaces:

- **CLI** — `o11y ask`, `o11y audit-repo`, `o11y review-plan`, `o11y review-collector`, `o11y review-alerts`, `o11y mcp serve`, `o11y skill install`
- **MCP server** — `o11y mcp serve` (stdio transport, usable by Claude Code and other agent harnesses)
- **Agent Skill** — packaged Claude Code skill for use in agentic coding workflows

## Architecture

Elixir/Phoenix backend (hosted on Fly.io) + Go CLI (single binary, zero runtime dependencies). See [ADR-0001](docs/adr/0001-polyglot-architecture.md) for the full rationale.

```
┌────────────────────────┐        HTTP/JSON        ┌──────────────────────────────┐
│   Go CLI / MCP proxy   │ ──────────────────────► │  Elixir/Phoenix + Arcana     │
│   (local binary)       │                         │  PostgreSQL + pgvector       │
└────────────────────────┘                         │  Hosted on Fly.io            │
                                                   └──────────────────────────────┘
```

The knowledge base (embeddings, graph, retrieval) lives in the hosted backend and is shared across users. The CLI is a thin client that formats results.

### Ingestion

Ingestion is a backend Mix task (`mix ingest.run`), run on demand and on a schedule — not at build or install time (see [ADR-0003](docs/adr/0003-ingestion-timing-and-semconv-pinning.md)). For each entry in the source registry it:

1. **Fetches** files matching the entry's `path_glob` at its pinned `version_pin` ref — the Git Trees API lists the repo tree, the glob filters it, and each match's raw Markdown is downloaded (`O11yAdvisor.Ingestion.GitHub`). Set `GITHUB_TOKEN`/`GH_TOKEN` to raise the API rate limit.
2. **Parses** each file into an `O11yAdvisor.Ingestion.Document` with PRD §8 metadata stamped on — `source_url`, `title`, `project`, `content_type`, `license`, `retrieved_at`, `version` (the pinned ref), and `section_path` (`O11yAdvisor.Ingestion.MarkdownParser`).

The full ingestion task chunks each parsed document, embeds chunks with Arcana's local `BAAI/bge-base-en-v1.5` embedder, and stores documents/chunks in Arcana's PostgreSQL + pgvector tables. Chunks retain source metadata for citation and version/license filtering.

## Repository layout

```
backend/        Elixir/Phoenix API (ExCoveralls + Credo configured)
cli/            Go CLI binary (cobra, zero runtime dependencies)
docs/
  adr/          Architecture Decision Records
LICENSE         MIT
PRD O11y Advisor MVP.md   Product requirements
CLAUDE.md       AI coding guidelines
CONTRIBUTING.md Development process
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branching strategy, commit conventions, how to run tests, and CI details.

## Related documents

- [Product Requirements (PRD)](PRD%20O11y%20Advisor%20MVP.md)
- [ADR-0001: Polyglot Architecture](docs/adr/0001-polyglot-architecture.md)
- [ADR-0002: Evaluation Framework](docs/adr/0002-eval-framework.md)
- [ADR-0003: Ingestion Timing & Semconv Pinning](docs/adr/0003-ingestion-timing-and-semconv-pinning.md)
- [ADR-0004: LLM Inference Provider](docs/adr/0004-llm-provider.md)
