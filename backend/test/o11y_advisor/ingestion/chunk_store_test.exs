defmodule O11yAdvisor.Ingestion.ChunkStoreTest do
  use O11yAdvisor.DataCase, async: false

  @moduletag :integration

  alias Arcana.Chunk
  alias O11yAdvisor.Ingestion.{ChunkStore, Document}

  defmodule StubChunker do
    @behaviour Arcana.Chunker

    @impl true
    def chunk(_text, _opts) do
      [
        %{text: "HTTP server span attributes", chunk_index: 0, token_count: 4},
        %{text: "Database client metrics", chunk_index: 1, token_count: 3}
      ]
    end
  end

  defmodule FakeEmbedder do
    @behaviour Arcana.Embedder

    @impl true
    def embed(text, _opts) do
      cond do
        String.contains?(text, "HTTP") -> {:ok, vector(1.0, 0.0)}
        String.contains?(text, "Database") -> {:ok, vector(0.0, 1.0)}
        true -> {:ok, vector(0.5, 0.5)}
      end
    end

    @impl true
    def dimensions(_opts), do: 768

    defp vector(first, second), do: [first, second] ++ List.duplicate(0.0, 766)
  end

  @metadata %{
    source_ref: "open-telemetry/semantic-conventions@v1.29.0:docs/http/http-spans.md",
    source_url:
      "https://github.com/open-telemetry/semantic-conventions/blob/v1.29.0/docs/http/http-spans.md",
    section_path: ["docs", "http"],
    license: "Apache-2.0",
    version: "v1.29.0",
    project: "OpenTelemetry",
    content_type: "specification",
    title: "HTTP Spans",
    retrieved_at: "2026-06-05"
  }

  test "stores a document with embedded chunks and chunk metadata" do
    document = %Document{content: "# HTTP Spans\n\nfixture", metadata: @metadata}

    assert {:ok, %{document: arcana_document, chunks: [_first, _second]}} =
             ChunkStore.store(document,
               chunker: {StubChunker, []},
               embedder: {FakeEmbedder, []}
             )

    assert arcana_document.status == :completed
    assert arcana_document.chunk_count == 2
    assert arcana_document.source_id == @metadata.source_ref

    chunks =
      Chunk
      |> where([chunk], chunk.document_id == ^arcana_document.id)
      |> order_by([chunk], asc: chunk.chunk_index)
      |> Repo.all()

    assert Enum.map(chunks, & &1.text) == [
             "HTTP server span attributes",
             "Database client metrics"
           ]

    assert [first_chunk, _second_chunk] = chunks
    assert first_chunk.metadata["source_ref"] == @metadata.source_ref
    assert first_chunk.metadata["section_path"] == ["docs", "http"]
    assert first_chunk.metadata["license"] == "Apache-2.0"
    assert first_chunk.metadata["version"] == "v1.29.0"
  end

  test "pgvector similarity query returns the nearest stored chunk" do
    document = %Document{content: "# HTTP Spans\n\nfixture", metadata: @metadata}

    assert {:ok, %{document: arcana_document}} =
             ChunkStore.store(document,
               chunker: {StubChunker, []},
               embedder: {FakeEmbedder, []}
             )

    query_embedding = Pgvector.new([1.0, 0.0] ++ List.duplicate(0.0, 766))

    nearest =
      Chunk
      |> where([chunk], chunk.document_id == ^arcana_document.id)
      |> order_by([chunk], fragment("? <=> ?", chunk.embedding, ^query_embedding))
      |> limit(1)
      |> Repo.one()

    assert nearest.text == "HTTP server span attributes"
  end
end
