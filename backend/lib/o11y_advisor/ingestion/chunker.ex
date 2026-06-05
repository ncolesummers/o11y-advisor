defmodule O11yAdvisor.Ingestion.Chunker do
  @moduledoc """
  Chunks parsed ingestion documents while preserving citation/filter metadata.
  """

  alias O11yAdvisor.Ingestion.Document

  @chunk_metadata_keys [
    :source_ref,
    :source_url,
    :section_path,
    :license,
    :version,
    :project,
    :content_type,
    :title,
    :retrieved_at
  ]

  @default_chunk_opts [
    format: :markdown,
    size_unit: :tokens,
    chunk_size: 450,
    chunk_overlap: 50
  ]

  @spec chunk(Document.t(), keyword()) :: [map()]
  def chunk(%Document{content: content, metadata: metadata}, opts \\ []) do
    chunker = Keyword.get(opts, :chunker, {Arcana.Chunker.Default, []})
    chunk_opts = build_chunk_opts(opts)
    chunk_metadata = Map.take(metadata, @chunk_metadata_keys)

    chunker
    |> Arcana.Chunker.chunk(content, chunk_opts)
    |> Enum.map(&with_metadata(&1, chunk_metadata))
  end

  defp build_chunk_opts(opts) do
    @default_chunk_opts
    |> Keyword.merge(Keyword.drop(opts, [:chunker]))
  end

  defp with_metadata(chunk, metadata) do
    chunk
    |> Map.take([:text, :chunk_index, :token_count])
    |> Map.put(:metadata, metadata)
  end
end
