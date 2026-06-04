defmodule O11yAdvisor.Ingestion do
  @moduledoc """
  GitHub ingestion pipeline: fetch Markdown for each registered source at its
  pinned ref and parse it into `Ingestion.Document` values ready for chunking
  (#18). Persists nothing — the handoff is in-memory.

  The fetcher is injectable via the `:github` option (default
  `O11yAdvisor.Ingestion.GitHub`) so tests can run without the network.
  """

  alias O11yAdvisor.Ingestion.{Document, GitHub, MarkdownParser}
  alias O11yAdvisor.SourceRegistry
  alias O11yAdvisor.SourceRegistry.Source

  @spec ingest_all(keyword()) :: [Document.t()]
  def ingest_all(opts \\ []) do
    SourceRegistry.list_sources()
    |> Enum.flat_map(&ingest_source(&1, opts))
  end

  @spec ingest_source(Source.t(), keyword()) :: [Document.t()]
  def ingest_source(%Source{} = source, opts \\ []) do
    github = Keyword.get(opts, :github, GitHub)

    case github.fetch_matching(source) do
      {:ok, files} ->
        Enum.map(files, fn {path, content} -> MarkdownParser.parse(content, path, source) end)

      {:error, reason} ->
        raise "ingestion failed for #{source.repo}@#{source.version_pin}: #{inspect(reason)}"
    end
  end
end
