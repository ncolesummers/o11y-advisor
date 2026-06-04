defmodule Mix.Tasks.Ingest.Run do
  use Mix.Task

  alias O11yAdvisor.Ingestion

  @shortdoc "Fetch + parse Markdown from registered GitHub sources"

  @moduledoc """
  Runs the GitHub ingestion pipeline (ADR-0003): for every source in the
  registry, fetch the Markdown matching its `path_glob` at its pinned
  `version_pin` and parse it into documents with PRD §8 metadata.

      mix ingest.run

  Documents are returned in memory (chunking + embedding is #18); this task
  prints a per-document summary so the stamped license + version are visible.
  Set `GITHUB_TOKEN` (or `GH_TOKEN`) to raise the GitHub API rate limit.
  """

  @spec run([String.t()]) :: :ok
  def run(args), do: run(args, ingestion: Ingestion, start_app?: true)

  @spec run([String.t()], keyword()) :: :ok
  def run(args, opts) do
    {_parsed, remaining, invalid} = OptionParser.parse(args, strict: [])

    cond do
      invalid != [] ->
        Mix.raise("Invalid ingest.run option(s): #{format_invalid_options(invalid)}")

      remaining != [] ->
        Mix.raise("Unexpected ingest.run argument(s): #{Enum.join(remaining, " ")}")

      true ->
        execute(opts)
    end
  end

  defp execute(opts) do
    if Keyword.get(opts, :start_app?, true), do: Mix.Task.run("app.start")

    ingestion = Keyword.fetch!(opts, :ingestion)
    documents = ingestion.ingest_all([])
    print_summary(documents)
    :ok
  end

  defp print_summary(documents) do
    Mix.shell().info("Ingested #{length(documents)} document(s)")

    Enum.each(documents, fn %{metadata: metadata} ->
      Mix.shell().info(
        "- #{metadata.title} [#{metadata.version}] #{metadata.license} :: #{metadata.source_url}"
      )
    end)
  end

  defp format_invalid_options(invalid) do
    Enum.map_join(invalid, ", ", fn {option, value} -> "#{option}=#{value}" end)
  end
end
