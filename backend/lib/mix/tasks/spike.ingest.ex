defmodule Mix.Tasks.Spike.Ingest do
  use Mix.Task

  @shortdoc "SPIKE #13 — throwaway ingestion-trigger prototype (delete with #16/#17)"

  @moduledoc """
  Throwaway prototype for spike #13 / ADR-0003.

  Proves the chosen ingestion model end to end on a single file:

    * **On-demand trigger** — ingestion is a backend-invoked job (a Mix task),
      not build-time or install-time. This is the smallest form of the PRD §16
      "CI refresh job".
    * **Ingestion-time version pinning** — the source is fetched at a pinned ref
      and that ref is stamped onto the document's `version` metadata.

  Reading only: no DB writes, no chunking, no embeddings. Those belong to
  stories #16/#17/#18. **Delete this task once #16/#17 land.**

      mix spike.ingest
  """

  # One seeded source, pinned. Mirrors the PRD §8 registry entry shape:
  # %{repo:, path:, license:, version_pin:}. Semconv is the version-sensitive case.
  @source %{
    repo: "open-telemetry/semantic-conventions",
    path: "docs/http/http-spans.md",
    license: "Apache-2.0",
    version_pin: "v1.29.0",
    project: "OpenTelemetry",
    content_type: "specification"
  }

  def run(_args) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    text = fetch(@source.repo, @source.version_pin, @source.path)

    # Stamp metadata at ingestion time (PRD §8). `version` is the pinned ref —
    # this is the value query-time semconv filtering keys on (ADR-0003).
    doc = %{
      source_url:
        "https://github.com/#{@source.repo}/blob/#{@source.version_pin}/#{@source.path}",
      title: List.last(String.split(@source.path, "/")),
      project: @source.project,
      content_type: @source.content_type,
      license: @source.license,
      retrieved_at: Date.utc_today() |> Date.to_iso8601(),
      version: @source.version_pin,
      section_path: section_path(@source.path),
      bytes: byte_size(text)
    }

    Mix.shell().info("Ingested document (pinned at #{@source.version_pin}):\n")
    Mix.shell().info(inspect(doc, pretty: true))
  end

  defp fetch(repo, ref, path) do
    url = ~c"https://raw.githubusercontent.com/#{repo}/#{ref}/#{path}"

    case :httpc.request(:get, {url, []}, [], body_format: :binary) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        body

      {:ok, {{_, status, _}, _headers, _body}} ->
        Mix.raise("fetch failed: HTTP #{status} for #{url}")

      {:error, reason} ->
        Mix.raise("fetch failed: #{inspect(reason)}")
    end
  end

  # Derive section_path from the repo path, e.g. "docs/http/http-spans.md"
  # -> ["docs", "http"]. Real glob-aware derivation is #17's job.
  defp section_path(path) do
    path |> String.split("/") |> Enum.drop(-1)
  end
end
