defmodule O11yAdvisor.Ingestion.ChunkerTest do
  use ExUnit.Case, async: true

  alias O11yAdvisor.Ingestion.{Chunker, Document}

  defmodule StubChunker do
    @behaviour Arcana.Chunker

    @impl true
    def chunk(_text, opts) do
      send(Keyword.fetch!(opts, :test_pid), {:chunk_opts, opts})

      [
        %{text: "# HTTP\n\nfirst section", chunk_index: 0, token_count: 5},
        %{text: "second section", chunk_index: 1, token_count: 3}
      ]
    end
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
    retrieved_at: "2026-06-05",
    ignored: "not chunk metadata"
  }

  test "chunks a document and preserves citation metadata on each chunk" do
    document = %Document{
      content: "# HTTP\n\nfirst section\n\nsecond section",
      metadata: @metadata
    }

    chunks = Chunker.chunk(document, chunker: {StubChunker, test_pid: self()})

    assert [
             %{
               text: "# HTTP\n\nfirst section",
               chunk_index: 0,
               token_count: 5,
               metadata: metadata
             },
             %{
               text: "second section",
               chunk_index: 1,
               token_count: 3,
               metadata: second_metadata
             }
           ] = chunks

    assert second_metadata == metadata

    assert metadata.source_ref ==
             "open-telemetry/semantic-conventions@v1.29.0:docs/http/http-spans.md"

    assert metadata.section_path == ["docs", "http"]
    assert metadata.license == "Apache-2.0"
    assert metadata.version == "v1.29.0"
    refute Map.has_key?(metadata, :ignored)
  end

  test "uses markdown token chunking defaults" do
    document = %Document{content: "# HTTP", metadata: @metadata}

    _chunks = Chunker.chunk(document, chunker: {StubChunker, test_pid: self()})

    assert_receive {:chunk_opts, opts}
    assert opts[:format] == :markdown
    assert opts[:size_unit] == :tokens
    assert opts[:chunk_size] == 450
    assert opts[:chunk_overlap] == 50
  end
end
