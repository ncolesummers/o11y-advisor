defmodule O11yAdvisor.Ingestion do
  @moduledoc """
  GitHub ingestion pipeline: fetch Markdown for each registered source at its
  pinned ref, parse it into `Ingestion.Document` values, and optionally store
  embedded chunks in Arcana's pgvector tables.

  The fetcher is injectable via the `:github` option (default
  `O11yAdvisor.Ingestion.GitHub`) so tests can run without the network.
  """

  alias O11yAdvisor.Ingestion.{ChunkStore, Document, GitHub, MarkdownParser}
  alias O11yAdvisor.SourceRegistry
  alias O11yAdvisor.SourceRegistry.Source

  @spec ingest_all(keyword()) :: [Document.t()]
  def ingest_all(opts \\ []) do
    SourceRegistry.list_sources()
    |> Enum.flat_map(&ingest_source(&1, opts))
  end

  @spec ingest_all_and_store(keyword()) :: {:ok, [map()]} | {:error, term()}
  def ingest_all_and_store(opts \\ []) do
    SourceRegistry.list_sources()
    |> Enum.reduce_while({:ok, []}, fn source, {:ok, acc} ->
      case ingest_source_and_store(source, opts) do
        {:ok, stored} -> {:cont, {:ok, acc ++ stored}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
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

  @spec ingest_source_and_store(Source.t(), keyword()) :: {:ok, [map()]} | {:error, term()}
  def ingest_source_and_store(%Source{} = source, opts \\ []) do
    chunk_store = Keyword.get(opts, :chunk_store, ChunkStore)

    source
    |> ingest_source(opts)
    |> chunk_store.store_all(opts)
  end
end
