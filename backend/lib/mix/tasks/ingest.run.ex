defmodule Mix.Tasks.Ingest.Run do
  use Mix.Task

  alias O11yAdvisor.Ingestion

  @shortdoc "Fetch, parse, chunk, embed, and store registered GitHub sources"

  @moduledoc """
  Runs the GitHub ingestion pipeline (ADR-0003): for every source in the
  registry, fetch the Markdown matching its `path_glob` at its pinned
  `version_pin`, parse it into documents with PRD §8 metadata, then store
  embedded chunks in Arcana's pgvector tables.

      mix ingest.run

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

    case ingestion.ingest_all_and_store([]) do
      {:ok, stored_documents} ->
        print_summary(stored_documents)
        :ok

      {:error, reason} ->
        Mix.raise("ingest.run failed: #{inspect(reason)}")
    end
  end

  defp print_summary(stored_documents) do
    Mix.shell().info(
      "Stored #{length(stored_documents)} document(s), #{total_chunks(stored_documents)} chunk(s)"
    )

    Enum.each(stored_documents, fn %{document: document} ->
      metadata = document.metadata || %{}

      Mix.shell().info(
        "- #{metadata_value(metadata, :title)} [#{metadata_value(metadata, :version)}] " <>
          "#{metadata_value(metadata, :license)} :: #{metadata_value(metadata, :source_url)}"
      )
    end)
  end

  defp total_chunks(stored_documents) do
    Enum.reduce(stored_documents, 0, fn %{chunks: chunks}, total -> total + length(chunks) end)
  end

  defp metadata_value(metadata, key),
    do: Map.get(metadata, key) || Map.get(metadata, Atom.to_string(key))

  defp format_invalid_options(invalid) do
    Enum.map_join(invalid, ", ", fn {option, value} -> "#{option}=#{value}" end)
  end
end
