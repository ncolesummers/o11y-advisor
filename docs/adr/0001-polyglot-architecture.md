# ADR-0001: Polyglot Architecture — Elixir Backend, Go CLI, Hosted Service

**Status:** Accepted  
**Date:** 2026-05-24

---

## Context

O11y Advisor needs three surfaces: a CLI for humans and agents, an MCP server for agent harnesses, and a RAG-backed knowledge base over the o11y documentation corpus. These three concerns pull in different directions when choosing a language and deployment model.

Key constraints driving this decision:

- The knowledge base (embeddings, graph) is shared across users — storing it locally per user wastes compute and makes corpus updates hard.
- The CLI must be zero-dependency for end users (single binary install via `brew` or `go install`).
- The MCP SDK ecosystem is mature in TypeScript and Go; Elixir community options exist but are less proven.
- Arcana (georgeguimaraes/arcana, Apache 2.0) is a well-designed graph RAG library for Elixir/Phoenix that maps cleanly to this problem: hybrid vector + keyword search, graph community detection, cross-encoder reranking, and Agentic RAG loop — all embedded in a Phoenix app using pgvector.
- The developer has production experience with Elixir and Go, making this a practical stack, not a novelty choice.

Alternative considered: single-language Python or Go monolith. Rejected because: (a) Python distributes poorly as a CLI, (b) Go would require reimplementing RAG capabilities Arcana already provides, and (c) neither uses a language the developer finds interesting for a side/portfolio project.

Alternative considered: Elixir CLI + Elixir MCP. Rejected because Elixir MCP SDK maturity is uncertain and Elixir does not distribute as a single binary without an Erlang runtime.

---

## Decision

**Elixir/Phoenix backend (hosted) + Go CLI (local binary).**

### Backend — Elixir/Phoenix + Arcana

- Phoenix application with Arcana embedded as the RAG engine.
- PostgreSQL + pgvector for documents, chunks, embeddings, and knowledge graph.
- Exposes a versioned HTTP/JSON API (`/api/v1/ask`, `/api/v1/audit`, etc.).
- Hosted on Fly.io (native BEAM support, managed Postgres, low operational overhead).
- Ingestion pipeline, eval harness, and knowledge base live here.
- Knowledge base is shared infrastructure — users do not run their own copy.

### CLI — Go

- Single compiled binary with no runtime dependency.
- Calls the hosted Elixir API; formats output as text, JSON, or Markdown.
- For MVP, also serves as the **MCP stdio server**: `o11y mcp serve` starts a stdio process the LLM harness speaks to, which proxies MCP tool calls to the Elixir API. This avoids the need for an Elixir MCP SDK at MVP.

### MCP transport strategy

| Mode | Transport | Auth | Timeline |
|---|---|---|---|
| MVP | stdio (Go binary proxies to Elixir API) | none required | MVP |
| Enterprise | StreamableHTTP + SSE (Elixir serves directly) | OAuth 2.0 or API keys | Post-MVP |

The two modes are additive: the Go binary remains the stdio surface; the Elixir backend grows a `/mcp` endpoint with auth for remote use.

---

## Consequences

**Positive:**
- Arcana provides graph RAG, reranking, and agentic loop out of the box — no reimplementing.
- Go CLI distributes as a single binary; zero friction for users.
- MCP stdio is simple and well-understood; defers auth complexity to a later milestone.
- Fly.io makes Elixir hosting straightforward; pgvector is the same Postgres instance.
- Architecture cleanly separates corpus management (backend) from interface concerns (CLI).

**Negative / trade-offs:**
- Two languages means two codebases to maintain. Acceptable for a side project; reviewer must understand both.
- Remote MCP with auth (enterprise path) requires a later Elixir MCP implementation. The HTTP API endpoints exist by then, so the work is bounded.
- Hosted backend means the CLI requires network access and a live backend. An offline mode (bundled snapshot) is deferred.
- Fly.io + Postgres has a small ongoing cost (~$5–15/month).

---

## Related

- PRD: `PRD O11y Advisor MVP.md` §15 (Technical Architecture), §7.2 (MCP Server)
- Arcana library: https://github.com/georgeguimaraes/arcana (Apache 2.0)
- MCP StreamableHTTP transport spec: https://modelcontextprotocol.io/specification/2025-03-26/basic/transports
