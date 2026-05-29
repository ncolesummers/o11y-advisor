# PRD: O11y Advisor MVP

## 1. Product Summary

**O11y Advisor** is a specialist observability and SRE advisory tool designed to help developers, coding agents, and platform teams make better decisions about telemetry, alerting, dashboards, incident response, and reliability practices.

The MVP exposes an open-source observability knowledge base through:

1. A local CLI
2. An MCP server for agent integrations
3. Agent Skill packaging for Claude Code (Codex, Cursor, and other harnesses are follow-on)
4. Optional CI/PR review workflows

The product is not intended to replace Grafana, Prometheus, OpenTelemetry, or incident-management platforms. Instead, it acts as a **domain expert advisor** that helps humans and agents apply those tools correctly.

---

## 2. Problem Statement

Modern observability systems are powerful but difficult to implement well. Teams often struggle with:

- Choosing the right telemetry signal: logs, metrics, traces, span events, or exemplars
- Instrumenting services consistently
- Avoiding high-cardinality metrics
- Writing useful PromQL or LogQL queries
- Designing actionable alerts instead of noisy alerts
- Configuring OpenTelemetry Collector pipelines
- Correlating traces, logs, and metrics
- Creating useful dashboards and runbooks
- Applying SRE concepts like SLIs, SLOs, and error budgets
- Teaching coding agents how to make good observability decisions while modifying code

General-purpose AI coding agents can write code, but they often lack deep, source-grounded observability judgment. O11y Advisor provides that specialist judgment as a reusable tool.

---

## 3. Goals

### MVP Goals

- Provide a source-grounded observability advisor for developers and coding agents.
- Support practical questions about OpenTelemetry, Prometheus, Grafana, Loki, Tempo, Jaeger, and SRE practices.
- Review repository artifacts such as telemetry code, Collector configs, alert rules, and runbooks.
- Expose the advisor through CLI and MCP interfaces.
- Package usage guidance as an Agent Skill so Claude Code agents know when to call it.
- Produce structured, actionable findings that can be consumed by humans, agents, or CI workflows.

### Non-Goals for MVP

- Build a full observability platform.
- Replace Grafana dashboards, Prometheus, Loki, Tempo, or Jaeger.
- Automatically deploy observability infrastructure.
- Build a full incident-management system.
- Support every programming language and framework.
- Guarantee production readiness for generated configs without human review.
- Fine-tune a model.
- Scrape unclear or proprietary sources.

---

## 4. Target Users

### Primary Users

#### 1. Application Developers

Developers who need to instrument services, add metrics, configure tracing, write alerts, or improve logs.

Example needs:

- “How should I instrument this FastAPI service?”
- “Should this be a metric or a span event?”
- “Is this alert noisy?”
- “How do I send traces to Tempo?”

#### 2. Coding Agents

Agentic coding tools such as Claude Code, Codex-style agents, Cursor, or CI-based coding agents that need specialist observability advice while editing a repo.

Example needs:

- Review a proposed instrumentation plan.
- Audit a diff for telemetry issues.
- Generate PromQL based on service context.
- Improve an OpenTelemetry Collector config.

#### 3. Platform / SRE Engineers

Engineers responsible for platform reliability, observability standards, runbooks, and alert quality.

Example needs:

- Standardize telemetry across services.
- Review alert rules.
- Generate service-level runbook templates.
- Help teams design SLIs and SLOs.

---

## 5. MVP Scope

The MVP should focus on a narrow but useful observability stack:

- **Language/framework:** Python + FastAPI
- **Instrumentation:** OpenTelemetry Python
- **Telemetry pipeline:** OpenTelemetry Collector
- **Metrics:** Prometheus
- **Visualization/alerting:** Grafana
- **Logs:** Loki
- **Traces:** Tempo and/or Jaeger
- **SRE practices:** SLIs, SLOs, alerting, runbooks, incident response basics

This scope is intentionally narrow to allow high-quality guidance and meaningful evaluation.

---

## 6. Core Use Cases

### Use Case 1: Ask an Observability Question

**As a developer,** I want to ask a source-grounded observability question so that I can make a better implementation decision.

Example:

```bash
o11y ask "Should failed form validation be a log, metric, span event, or exception?"
```

Expected behavior:

- Answer with a clear recommendation.
- Explain tradeoffs.
- Cite or reference relevant knowledge base sources.
- Include implementation guidance where useful.
- Identify assumptions.

---

### **Use Case 2: Review an Instrumentation Plan**

**As a coding agent,** I want to submit an instrumentation plan for review before editing code so that I avoid weak telemetry design.

Example:

```bash
o11y review-plan plan.md --stack fastapi
```

Expected behavior:

- Identify missing telemetry signals.
- Recommend appropriate spans, metrics, and logs.
- Warn about cardinality risks.
- Suggest semantic convention alignment.
- Return structured findings.

---

### **Use Case 3: Audit a Repository**

**As a developer or agent,** I want to audit a repository for observability coverage so that I can identify gaps before production deployment.

Example:

```bash
o11y audit-repo --path . --stack fastapi
```

Expected behavior:

- Inspect relevant files.
- Detect likely instrumentation patterns.
- Identify missing tracing, metrics, logging, or correlation.
- Flag high-risk patterns.
- Produce human-readable and JSON output.
Potential findings:

- No OpenTelemetry SDK initialization found.
- HTTP client calls are not instrumented.
- Logs do not include trace IDs.
- Metrics use raw paths as labels.
- No health or readiness endpoint found.
- No Prometheus rules found.
- No runbook found for service alerts.

---

### **Use Case 4: Review OpenTelemetry Collector Config**

**As a platform engineer,** I want to review an OpenTelemetry Collector config so that I can catch misconfigurations and improve pipeline design.

Example:

```bash
o11y review-collector ./otel-collector.yaml
```

Expected behavior:

- Validate structure conceptually.
- Identify missing receivers, processors, exporters, or pipelines.
- Recommend batching, memory limits, resource detection, or filtering where appropriate.
- Flag insecure or fragile configurations.
- Explain what each pipeline does.

---

### **Use Case 5: Review Prometheus Alert Rules**

**As an SRE or developer,** I want to review Prometheus alert rules so that alerts are actionable and not noisy.

Example:

```bash
o11y review-alerts ./prometheus/rules
```

Expected behavior:

- Evaluate alert actionability.
- Detect missing `for` durations.
- Detect overly sensitive thresholds.
- Identify missing labels or annotations.
- Suggest runbook links.
- Identify symptoms that should use SLO-based alerting instead.
- Return severity-ranked findings.

---

### **Use Case 6: Generate PromQL or LogQL**

**As a developer,** I want help writing PromQL or LogQL so that I can query metrics or logs correctly.

Example:

```bash
o11y write-promql "p95 latency by route for a FastAPI service over the last 5 minutes"
```

Expected behavior:

- Generate a query.
- Explain assumptions about metric names and labels.
- Provide alternatives if metric names are unknown.
- Warn about histogram requirements and label cardinality.

---

### **Use Case 7: Design an SLO**

**As a service owner,** I want help designing an SLO so that I can define reliability targets for a service.

Example:

```bash
o11y design-slo \
  --service registration-api \
  --tier user-facing \
  --availability-target 99.9 \
  --latency-target "95% under 300ms"
```

Expected behavior:

- Recommend candidate SLIs.
- Propose SLO targets.
- Suggest error-budget alerts.
- Identify telemetry prerequisites.
- Generate a starter SLO document.

---

### **Use Case 8: Generate or Review a Runbook**

**As an on-call engineer,** I want help creating or reviewing a runbook so that incidents can be handled consistently.

Example:

```bash
o11y create-runbook \
  --service registration-api \
  --alerts ./prometheus/rules/registration-api.yaml
```

Expected behavior:

- Generate runbook sections:
  - Symptoms
  - Impact
  - Initial checks
  - Dashboards
  - PromQL queries
  - LogQL queries
  - Trace investigation
  - Escalation criteria
  - Rollback steps
  - Post-incident follow-up
- Keep recommendations grounded in available repo context.

---

### **Use Case 9: Advisor for Coding Agents**

**As a coding agent,** I want to call O11y Advisor during implementation so that I can make observability-aware code changes.

Example workflow:

```bash
User asks coding agent:
"Add OpenTelemetry to this FastAPI app."

Coding agent:
1. Scans repo.
2. Calls O11y Advisor for an implementation plan.
3. Edits files.
4. Calls O11y Advisor to review the diff.
5. Runs tests.
6. Summarizes changes and remaining risks.
```

Expected behavior:

- O11y Advisor returns concise, structured advice.
- It does not attempt to directly own the entire coding task.
- It acts as a domain expert reviewer.

---

## **7. Product Interfaces**

### **7.1 CLI**

The CLI is the primary MVP interface for humans, scripts, CI, and coding agents.

MVP command surface:

```bash
o11y ask "<question>"
o11y audit-repo --path .
o11y review-plan plan.md
o11y review-collector ./otel-collector.yaml
o11y review-alerts ./prometheus/rules
o11y mcp serve
o11y skill install claude
```

Milestone 2 commands (PromQL/LogQL generation — deferred):

```bash
o11y write-promql "<request>"
o11y write-logql "<request>"
```

Milestone 3 commands (SLO design and runbook generation — deferred):

```bash
o11y design-slo --service <name>
o11y create-runbook --service <name>
```

CLI output modes:

```bash
--format text
--format json
--format markdown
```

Default output should be human-readable Markdown.

JSON output should be stable enough for agents and CI.

## 7.2 MCP Server

The MCP server exposes O11y Advisor as a set of callable tools.\

Proposed tools:

| Tool | Purpose |
| :-: | :-: |
| ask_o11y_expert | General observability Q&A |
| review_instrumentation_plan | Review a proposed telemetry plan |
| audit_repository_observability | Audit repo-level observability coverage |
| review_otel_collector_config | Review Collector YAML |
| review_prometheus_rules | Review alert and recording rules |
| write_promql | Generate PromQL |
| write_logql | Generate LogQL |
| design_slo | Recommend SLIs, SLOs, and alerts |
| create_runbook | Generate an incident runbook |
| review_observability_diff | Review a proposed code diff for telemetry quality |

MCP responses should include:

- Summary
- Findings
- Recommendations
- Severity
- Evidence
- Source references
- Confidence
- Machine-readable JSON payload

## 7.3 Agent Skill

The Agent Skill should not contain the entire knowledge base. It should teach agents **when and how to call O11y Advisor**.

**MVP scope:** Target Claude Code only. The `SKILL.md` format is Claude Code-native. Codex and Cursor support is follow-on.

Proposed structure:

```plaintext
o11y-advisor/
  SKILL.md
  scripts/
    o11y-advisor.sh
  references/
    telemetry-decision-tree.md
    alert-quality-rubric.md
    slo-design-template.md
    collector-review-checklist.md
```

The skill should instruct agents to consult O11y Advisor when:

- Adding or modifying OpenTelemetry instrumentation
- Writing metrics
- Writing structured logs
- Adding trace correlation
- Changing Collector configs
- Creating Prometheus rules
- Creating Grafana dashboards
- Writing runbooks
- Investigating production incidents
- Reviewing reliability-related code

## 8. Knowledge Base Scope

### MVP Sources

Use high-quality open and official sources where possible.

Core source families:

- OpenTelemetry documentation
- OpenTelemetry specification
- OpenTelemetry semantic conventions
- OpenTelemetry Collector documentation
- Prometheus documentation
- PromQL documentation
- Grafana documentation
- Loki documentation
- LogQL documentation
- Tempo documentation
- Jaeger documentation
- PagerDuty Incident Response Docs — `PagerDuty/incident-response-docs` on GitHub, Apache 2.0. Covers incident response, runbook structure, and on-call practices.
- USENIX/SREcon papers — CC BY licensed papers on SLO design, alerting philosophy, and error budgets. (Curated paper list maintained in source registry.)
- OpenSLO spec — `OpenSLO/oslo` on GitHub, Apache 2.0. Formalizes SLO/SLI structure; directly useful for the `design-slo` command.
- Agent-authored SRE concept documents — First-party KB entries written by an agent capturing SRE concepts (SLI/SLO/error budget definitions, alerting philosophy, incident response patterns), citing Google SRE book chapters by name. Owned documents with no third-party license constraint.
- CNCF Observability Whitepaper (explicit open license)
- CNCF blog posts tagged `observability` (ToS-permissible)
- Curated examples from official repositories (Apache 2.0 only; enumerated in source registry)

### Ingestion Strategy

Default ingestion path is **GitHub repo source**, not rendered websites. This avoids robots.txt restrictions, Terms of Service constraints on doc hosting sites, and JavaScript-rendered content issues.

Each source in the source registry must specify:

```json
{
  "repo": "open-telemetry/opentelemetry-specification",
  "path_glob": "specification/**/*.md",
  "license": "Apache-2.0",
  "version_pin": "v1.39.0"
}
```

Web scraping is a secondary path only for sources with no suitable GitHub repo. Any web-scraped source requires explicit approval and confirmed ToS/robots.txt compatibility.

### Source Metadata

Every ingested document should store:

```json
{
  "source_url": "...",
  "title": "...",
  "project": "OpenTelemetry",
  "content_type": "docs",
  "license": "...",
  "retrieved_at": "2026-05-24",
  "version": "...",
  "section_path": ["Docs", "Instrumentation", "Python"],
  "text": "..."
}
```

### Content Types

The knowledge base should distinguish between:

| Type | Example |
| :-: | :-: |
| Concept docs | “What is a span?” |
| Specification | OTel semantic conventions |
| Configuration reference | Collector processors/exporters |
| Query reference | PromQL / LogQL |
| Code example | FastAPI instrumentation |
| Operational guidance | Alerting, SLOs, runbooks |
| Troubleshooting | Common failure modes |
| Templates | Runbook, dashboard, SLO template |

## 9. Retrieval Requirements

### The MVP should support hybrid retrieval

### Retrieval Capabilities

- Semantic/vector search

- Keyword/full-text search
- Source filtering by project
- Topic filtering
- Version-aware retrieval required for OTel semantic conventions (versioned per-signal; mixed-version retrieval produces incorrect attribute name advice); best-effort for other sources
- Code/config-aware chunking
- Citation/source return
- Reranking if available

⠀Desired Retrieval Behavior

### For a question like

### “How should I instrument outbound HTTP calls in FastAPI?”

### The system should retrieve

- OTel Python instrumentation docs

- HTTP semantic conventions
- Relevant FastAPI example
- Context propagation guidance
- Collector/export path if needed

⠀It should not only retrieve generic observability concepts.

⸻

## 10. Repository Audit Requirements

### The MVP repository auditor should inspect common files and patterns

### Files to Detect

- pyproject.toml

- requirements.txt
- Dockerfile
- docker-compose.yml
- Kubernetes manifests
- Helm charts
- otel-collector.yaml
- Prometheus rule files
- Grafana dashboard JSON
- FastAPI app entrypoints
- logging config
- middleware
- HTTP client usage
- tests
- README/runbook files

### Python/FastAPI Checks

- Is OpenTelemetry SDK configured?
- Is FastAPI instrumentation present?
- Are HTTP clients instrumented?
- Are database clients instrumented where detectable?
- Are logs structured?
- Do logs include trace/span correlation?
- Are custom metrics present?
- Are metric labels likely bounded?
- Are health/readiness endpoints present?
- Are errors recorded in traces?
- Is service name/resource metadata configured?
- Is configuration environment-driven?
- Are telemetry dependencies included?

### Alert Rule Checks

- Alert has clear name.
- Alert has for duration where appropriate.
- Alert has severity label.
- Alert has summary and description.
- Alert has runbook link or suggested remediation.
- Expression avoids obvious cardinality problems.
- Alert appears actionable.
- Alert is not purely informational unless labeled as such.
- Alert is tied to user impact where possible.

⠀
⸻

## 11. Output Model

### Findings should use a stable schema

```json
{
  "summary": "Repository has partial tracing but weak metrics and no alerting coverage.",
  "score": 68,
  "findings": [
    {
      "id": "missing-http-client-instrumentation",
      "severity": "high",
      "category": "tracing",
      "message": "Outbound HTTP client calls do not appear to be instrumented.",
      "evidence": [
        "src/app/services/banner_client.py"
      ],
      "recommendation": "Add instrumentation for the HTTP client library and verify trace context propagation.",
      "sources": [
        {
          "title": "OpenTelemetry Python instrumentation",
          "url": "..."
        }
      ],
      "confidence": "medium"
    }
  ],
  "next_actions": [
    "Add HTTP client instrumentation.",
    "Add trace ID correlation to logs.",
    "Create initial RED metrics dashboard."
  ]
}
```

### Severity levels

- critical

- high
- medium
- low
- info

⠀Confidence levels:

| Level | Meaning |
| --- | --- |
| `high` | Retrieval score above threshold **and** multiple corroborating chunks from ≥2 distinct sources |
| `medium` | Retrieval score above threshold **or** single strong source with direct relevance |
| `low` | Weak retrieval score, extrapolation beyond retrieved content, or model knowledge without KB backing |

⠀
⸻

## 12\. Example Agent Workflow

### Scenario

### A developer asks Claude Code or Codex

### “Add OpenTelemetry tracing and metrics to this FastAPI service.”

### Expected Workflow

1. Agent scans repository.
2. Agent calls:

```bash
o11y audit-repo --path . --format json
```

1. Agent calls:

```bash
o11y ask "Given this audit result, what implementation plan should I follow for FastAPI + OpenTelemetry + Prometheus?"
```

1. Agent implements changes.
2. Agent calls:

```bash
o11y review-diff --format json
```

1. Agent fixes high-severity findings.
2. Agent runs tests.
3. Agent summarizes:
   - Files changed
   - Telemetry added
   - Remaining gaps
   - Manual verification steps

⠀
⸻

## 13. MVP Success Metrics

### Functional Metrics

- Can answer common OTel/Prometheus/Grafana questions with citations.
- Can review a basic OpenTelemetry Collector config.
- Can review simple Prometheus alert rules.
- Can audit a FastAPI repo and identify meaningful gaps.
- Can produce JSON findings usable by another agent.
- Can run as a CLI.
- Can run as an MCP server.
- Can be packaged as an Agent Skill.

### Quality Metrics

- At least 80% of eval questions answered correctly or acceptably.
- At least 90% of answers include relevant source references.
- Fewer than 10% of answers include unsupported claims.
- Repository audit findings should be actionable, not generic.
- High-severity findings should have low false-positive rates.
- Generated PromQL should include assumptions when metric names are unknown.

### Portfolio Metrics

- Demonstrates practical RAG beyond chat.
- Demonstrates integration with agent harnesses.
- Demonstrates eval-driven development.
- Demonstrates source/licensing discipline.
- Demonstrates real-world observability/SRE value.

⠀
⸻

## 14. Evaluation Plan

Create an evaluation dataset with 100–200 test cases.

### Eval Categories

| Category | Example |
| :-: | :-: |
| Concept selection | “Should this be a metric, log, span, or span event?” |
| OTel instrumentation | “How do I instrument FastAPI?” |
| Collector config | “Review this Collector YAML.” |
| PromQL | “Write p95 latency query by route.” |
| Alert quality | “Is this alert actionable?” |
| Cardinality | “What is wrong with using user ID as a metric label?” |
| SLO design | “Define SLIs for a user-facing API.” |
| Incident response | “What should an on-call engineer check first?” |
| Multi-hop | “How do FastAPI traces reach Grafana Tempo through the Collector?” |
| Agent review | “Review this diff for telemetry quality.” |

### Eval Output**

Each eval should include:

```json
{
  "id": "eval-otel-fastapi-001",
  "question": "How should I instrument a FastAPI service with OpenTelemetry?",
  "expected_topics": [
    "FastAPI instrumentation",
    "OpenTelemetry SDK",
    "resource/service name",
    "OTLP exporter",
    "Collector pipeline"
  ],
  "must_not_include": [
    "vendor-specific requirement unless asked"
  ],
  "source_requirements": [
    "OpenTelemetry Python docs"
  ]
}
```

### Retrieval Quality Eval

Answer quality evals and retrieval quality evals are distinct tracks that require different fixes when they fail. Each eval case should also specify:

```json
{
  "id": "eval-otel-fastapi-001",
  "expected_sources": [
    "open-telemetry/opentelemetry-specification",
    "open-telemetry/opentelemetry.io"
  ],
  "retrieval_k": 5,
  "required_recall": 0.8
}
```

A failing **answer quality** eval means the model gave wrong or incomplete advice given the retrieved context — fix the prompt or model.
A failing **retrieval quality** eval means the right sources weren't surfaced — fix chunking, embedding, or query formulation.

## 15. Technical Architecture

### Repository Layout

```plaintext
o11y-advisor/
  backend/    Elixir/Phoenix — RAG engine, API, ingestion, evals
  cli/        Go — single binary, MCP stdio proxy
  skill/      Agent Skill packaging (SKILL.md, helper scripts)
  docs/       ADRs and supporting documentation
```

### Runtime Components

```plaintext
Source Repo Registry (repo, path_glob, license, version_pin)
      |
      v
Ingestion Pipeline (GitHub API → parse → chunk → embed)
      |
      v
Knowledge Store (metadata + vector embeddings)
      |
      v
Retrieval Layer (hybrid: vector + keyword + rerank)
      |
      v
Advisor API
      |
      v
CLI / MCP / CI
```

### Implementation Stack

Decided in [ADR-0001](docs/adr/0001-polyglot-architecture.md) and [ADR-0002](docs/adr/0002-eval-framework.md).

**Backend — Elixir/Phoenix (hosted on Fly.io)**

- **Language:** Elixir/Phoenix
- **RAG engine:** Arcana (graph RAG — hybrid vector + keyword search, graph community detection, cross-encoder reranking)
- **Storage:** PostgreSQL + pgvector (documents, chunks, embeddings, knowledge graph)
- **Embeddings:** `text-embedding-3-small` (OpenAI) for MVP; evaluate `nomic-embed-text` for offline mode
- **Docs ingestion:** GitHub API (primary); Markdown parser for `.md` files; HTML fallback for sources without a public repo
- **Testing:** ExUnit; integration tests require real Postgres (no mocks)
- **Eval:** Arcana eval (retrieval quality); Tribunal (answer quality + structured output validity) — see ADR-0002
- **Lint/format:** `mix format`

**CLI — Go (local binary)**

- **Language:** Go
- **Distribution:** single compiled binary, zero runtime dependency (`brew` or `go install`)
- **MCP transport (MVP):** `o11y mcp serve` runs as a stdio process and proxies MCP tool calls to the Elixir API
- **Output formats:** text, JSON, Markdown
- **Testing:** `go test`; coverage ≥ 80% enforced in CI
- **Lint/format:** `gofmt` + `goimports`

⠀
⸻

## 16. Risks and Mitigations

| Risk | Impact | Mitigation |
| :-: | :-: | :-: |
| Source licensing complexity | High | Ingestion defaults to GitHub repo source (not web scraping). Google SRE books excluded from ingestion (CC BY-NC-ND 4.0 prohibits derivatives); replaced with Apache 2.0 / CC BY equivalents. All sources tracked in source registry with explicit license field. |
| Hallucinated advice | High | Require citations; use evals; return confidence |
| Generic findings | Medium | Use repo evidence and file paths in findings |
| Too broad a scope | High | Start with Python/FastAPI + OTel + Prometheus + Grafana |
| Noisy audit false positives | Medium | Use confidence levels; make high-severity findings conservative |
| Agent misuse | Medium | Skill should tell agents to treat advice as review guidance, not absolute truth |
| Docs drift | High for semconv | OTel ships monthly; semconv is versioned per-signal. Semconv version pins are required. Implement CI refresh job. Store retrieval dates and source versions for all sources. |
| Query/config generation errors | High | Include assumptions and validation warnings |

## 17\. Suggested MVP Milestones

### Milestone 1: Knowledge Base Prototype

- Ingest initial docs via source repo registry.

- Support basic `o11y ask`.
- Return source-grounded answers.
- Create 20 initial evals (answer quality + retrieval quality).

⠀Milestone 2: CLI Advisor

- Add core MVP CLI commands (`ask`, `audit-repo`, `review-plan`, `review-collector`, `review-alerts`, `mcp serve`, `skill install`).
- Add structured JSON output.
- Add `write-promql` and `write-logql` (requires prompt templates + eval).
- Add Collector config review.

⠀Milestone 3: Repository Audit + SLO/Runbook

- Implement FastAPI repo scanning.
- Detect basic telemetry patterns.
- Return severity-ranked findings.
- Add `design-slo` and `create-runbook` (shares retrieval + structured-output pattern with audit; benefits from same eval infrastructure).

⠀Milestone 4: MCP Integration

- Expose core tools over MCP.
- Test with Claude Code or another MCP-compatible agent.
- Document example workflows.

⠀Milestone 5: Agent Skill

- Package SKILL.md.
- Add helper scripts.
- Add AGENTS.md generator.
- Test with a repo-level agent workflow.

⠀Milestone 6: Portfolio Demo

- Create demo repo.
- Record or document a full workflow:
  - agent audits repo
  - advisor recommends plan
  - agent implements changes
  - advisor reviews diff
  - tests pass
  - summary generated

⠀
⸻

## 18\. Decisions and Open Questions

**Resolved for MVP:**

- MCP server wraps CLI internals (not a separate API layer). The Go CLI binary is the MCP stdio server.
- Agent Skill targets Claude Code for MVP; Codex and Cursor are follow-on.
- Embeddings: `text-embedding-3-small` for MVP.
- Ingestion: GitHub repo source is the default; web scraping is secondary and requires explicit approval.
- Storage: hosted PostgreSQL + pgvector on Fly.io. Local vector store and SQLite are not used. Knowledge base is shared infrastructure; users do not run their own copy. (ADR-0001)
- Offline mode: deferred. The CLI requires network access to the hosted backend. A bundled snapshot may be added post-MVP. (ADR-0001)
- CI strictness: hard-fail on correctness invariants (schema validity, `must_not_include` violations, banned source citations) on every CI run; threshold-based quality metrics (≥80% correct, ≥90% with citations, <10% unsupported claims) on PR merge and nightly. (ADR-0002)

**Open Questions:**

- Should source ingestion happen at build time, install time, or on demand?
- Should semconv version pinning be enforced at ingestion time, query time, or both?
- Should the project include generated Grafana dashboards in MVP or defer them?
- Should the advisor support organization-specific observability standards later?

⠀
⸻

## 19\. One-Sentence MVP Definition

### O11y Advisor MVP is a CLI, MCP server, and Agent Skill that gives humans and coding agents source-grounded guidance for OpenTelemetry, Prometheus, Grafana, and SRE workflows, with special support for auditing Python/FastAPI repositories, reviewing Collector configs, reviewing alert rules, and generating practical observability recommendations
