# Contributing

Development process for o11y-advisor.

---

## Branching strategy

**GitHub Flow** — `main` is always stable; all work happens on short-lived feature branches.

```
main  ←── feat/knowledge-ingestion
      ←── fix/embed-timeout
      ←── ci/go-coverage-threshold
      ←── docs/mcp-transport
```

Branch naming: `<type>/<short-description>`

- Types: `feat`, `fix`, `ci`, `docs`, `test`, `chore`, `refactor`
- Keep branches focused — one concern per branch
- PRs required to merge to `main`, even when working solo

## Commit conventions

[Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <description>
```

**Types:** `feat`, `fix`, `docs`, `test`, `ci`, `refactor`, `chore`

**Scopes:** `backend`, `cli`, `mcp`, `evals`, `adr`, `docs`

Examples:
```
feat(backend): add hybrid search endpoint
fix(cli): handle API timeout gracefully
test(evals): add 20 initial retrieval eval cases
ci: add Elixir coverage threshold check
docs(adr): add ADR-0003 for auth strategy
```

Breaking changes: add `!` after the type (`feat(backend)!: change /ask response schema`) and include a `BREAKING CHANGE:` footer.

## Pull request process

Use the PR template (`.github/PULL_REQUEST_TEMPLATE.md`). Before merging:

1. All CI checks pass
2. Coverage ≥ 80% maintained
3. Format clean (`mix format` / `gofmt`)
4. Relevant docs updated if behavior changed
5. ADR written if the change involves a hard-to-reverse architectural decision

PRs should be small and focused. If a PR is getting large, split it.

## Testing

### Coverage target: ≥ 80% line coverage across both codebases

**Elixir backend:**

```bash
# Run tests with coverage
mix test --cover

# Run only fast unit tests (excludes :integration tag)
mix test --exclude integration

# Run hard-fail eval subset (schema + must_not_include checks)
mix test --only hard_fail
```

ExCoveralls enforces the 80% threshold in CI. Add `{:excoveralls, "~> 0.18", only: :test}` to `mix.exs`.

Integration tests hit a real Postgres instance (pgvector). Do not mock the database. Use Docker locally:

```bash
docker compose up -d postgres
mix test
```

**Go CLI:**

```bash
# Run tests with coverage report
go test ./... -coverprofile=coverage.out -covermode=atomic
go tool cover -func=coverage.out

# Run specific package
go test ./internal/api/...
```

CI fails if total coverage drops below 80%.

### Eval tests (Elixir backend only)

Evals are split into two tiers (per [ADR-0002](docs/adr/0002-eval-framework.md)):

| Tier | When | What |
|------|------|------|
| Hard-fail (ExUnit) | Every CI run | Schema validity, `must_not_include` violations, banned source citations |
| Threshold-based (Mix eval tasks) | PR to `main` + nightly | ≥80% correct, ≥90% with citations, <10% unsupported claims |

To run threshold evals locally:

```bash
mix eval.run          # full eval suite
mix eval.run --quick  # retrieval evals only (faster)
```

Threshold evals call an LLM — set `ANTHROPIC_API_KEY` in your environment.

## Code style

**Elixir:** `mix format` is enforced in CI. Run it before committing.

**Go:** `gofmt` and `goimports` are enforced. Run:

```bash
gofmt -l -w .
goimports -l -w .
```

No linter suppressions (`# credo:disable-for-this-file`, `//nolint`) without a comment explaining why.

## ADR process

Write an ADR when the decision is:
- Hard to reverse, or
- Affects multiple components, or
- Involves a significant trade-off that future contributors should understand

**Template:** Follow the pattern in `docs/adr/0001-polyglot-architecture.md`:
- Status (Proposed / Accepted / Superseded)
- Context — what constraints drive the decision
- Decision — what we chose and why
- Consequences — positive and negative trade-offs
- Related — links to PRD sections and related ADRs

**Numbering:** Next is `0004`. Place at `docs/adr/NNNN-<slug>.md`.

## Local development setup

Prerequisites will be documented here once the backend and CLI directories exist. Coming in Milestone 1:

- Elixir 1.17+ / OTP 27
- Go 1.23+
- Docker (for Postgres + pgvector)
- `ANTHROPIC_API_KEY` for eval and LLM-as-judge features
