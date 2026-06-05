defmodule O11yAdvisor.Ingestion.ChunkStore do
  @moduledoc """
  Stores parsed ingestion documents as Arcana documents and embedded chunks.
  """

  alias Arcana.{Chunk, Collection, Document, Embedder}
  alias O11yAdvisor.Ingestion.Chunker
  alias O11yAdvisor.Repo

  @default_collection "default"

  @spec store(O11yAdvisor.Ingestion.Document.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def store(document, opts \\ []) do
    repo = Keyword.get(opts, :repo, Repo)

    repo.transaction(fn ->
      case do_store(document, opts, repo) do
        {:ok, result} -> result
        {:error, reason} -> repo.rollback(reason)
      end
    end)
    |> case do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec store_all([O11yAdvisor.Ingestion.Document.t()], keyword()) ::
          {:ok, [map()]} | {:error, term()}
  def store_all(documents, opts \\ []) when is_list(documents) do
    Enum.reduce_while(documents, {:ok, []}, fn document, {:ok, acc} ->
      case store(document, opts) do
        {:ok, result} -> {:cont, {:ok, [result | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, results} -> {:ok, Enum.reverse(results)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_store(document, opts, repo) do
    with {:ok, source_ref} <- fetch_source_ref(document.metadata),
         {:ok, collection} <- Collection.get_or_create(collection_name(opts), repo),
         {:ok, arcana_document} <- insert_document(document, source_ref, collection, repo),
         chunks = Chunker.chunk(document, chunk_opts(opts)),
         {:ok, chunk_records} <- insert_chunks(chunks, arcana_document, opts, repo),
         {:ok, completed_document} <- complete_document(arcana_document, chunk_records, repo) do
      {:ok, %{document: completed_document, chunks: chunk_records}}
    end
  end

  defp collection_name(opts), do: Keyword.get(opts, :collection, @default_collection)

  defp chunk_opts(opts),
    do: Keyword.take(opts, [:chunker, :chunk_size, :chunk_overlap, :format, :size_unit])

  defp fetch_source_ref(metadata) do
    case Map.get(metadata, :source_ref) || Map.get(metadata, "source_ref") do
      nil -> {:error, :missing_source_ref}
      source_ref -> {:ok, source_ref}
    end
  end

  defp insert_document(document, source_ref, collection, repo) do
    %Document{}
    |> Document.changeset(%{
      content: document.content,
      content_type: metadata_value(document.metadata, :content_type) || "text/markdown",
      source_id: source_ref,
      metadata: document.metadata,
      status: :processing,
      collection_id: collection.id
    })
    |> repo.insert()
  end

  defp insert_chunks(chunks, document, opts, repo) do
    embedder = Keyword.get_lazy(opts, :embedder, &Arcana.Config.embedder/0)

    Enum.reduce_while(chunks, {:ok, []}, fn chunk, {:ok, acc} ->
      case insert_chunk(chunk, document, embedder, repo) do
        {:ok, chunk_record} -> {:cont, {:ok, [chunk_record | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, chunk_records} -> {:ok, Enum.reverse(chunk_records)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp insert_chunk(chunk, document, embedder, repo) do
    case Embedder.embed(embedder, chunk.text, intent: :document) do
      {:ok, embedding} ->
        %Chunk{}
        |> Chunk.changeset(%{
          text: chunk.text,
          embedding: embedding,
          chunk_index: chunk.chunk_index,
          token_count: chunk.token_count,
          metadata: chunk.metadata,
          document_id: document.id
        })
        |> repo.insert()

      {:error, reason} ->
        {:error, {:embedding_failed, reason}}
    end
  end

  defp complete_document(document, chunk_records, repo) do
    document
    |> Document.changeset(%{status: :completed, chunk_count: length(chunk_records)})
    |> repo.update()
  end

  defp metadata_value(metadata, key),
    do: Map.get(metadata, key) || Map.get(metadata, Atom.to_string(key))
end
