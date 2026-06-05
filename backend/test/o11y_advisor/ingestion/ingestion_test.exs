defmodule O11yAdvisor.Ingestion.StubFetcher do
  @moduledoc false
  # Returns fixed fixture files so the integration test is deterministic and
  # offline. The DB (source registry) is real per CONTRIBUTING; only the network
  # fetch is stubbed.
  def fetch_matching(_source) do
    {:ok,
     [
       {"docs/http/http-spans.md", "# HTTP Spans\n\nattribute reference.\n"},
       {"docs/general/attributes.md", "# Attributes\n\ngeneral attributes.\n"}
     ]}
  end
end

defmodule O11yAdvisor.Ingestion.StubChunkStore do
  @moduledoc false

  def store_all(documents, _opts) do
    {:ok, Enum.map(documents, fn document -> %{document: document, chunks: []} end)}
  end
end

defmodule O11yAdvisor.IngestionTest do
  use O11yAdvisor.DataCase, async: false

  @moduletag :integration

  alias O11yAdvisor.Ingestion
  alias O11yAdvisor.Ingestion.Document
  alias O11yAdvisor.Ingestion.StubChunkStore
  alias O11yAdvisor.Ingestion.StubFetcher
  alias O11yAdvisor.SourceRegistry

  # A synthetic source so the test can never collide with real registry seeds.
  @source_attrs %{
    repo: "test-org/fixture-repo",
    path_glob: "docs/**/*.md",
    license: "Apache-2.0",
    version_pin: "v0.0.0-fixture",
    project: "FixtureProject",
    content_type: "docs"
  }

  test "ingests a registered source into documents carrying license + version" do
    {:ok, _source} = SourceRegistry.create_source(@source_attrs)

    documents = Ingestion.ingest_all(github: StubFetcher)

    assert length(documents) == 2

    assert Enum.all?(documents, fn %Document{metadata: metadata} ->
             metadata.license == "Apache-2.0" and metadata.version == "v0.0.0-fixture"
           end)

    titles = Enum.map(documents, & &1.metadata.title)
    assert "HTTP Spans" in titles
    assert "Attributes" in titles
  end

  test "stores ingested documents without reversing source or document order" do
    {:ok, _source} =
      @source_attrs
      |> Map.put(:repo, "a-org/fixture-repo")
      |> SourceRegistry.create_source()

    {:ok, _source} =
      @source_attrs
      |> Map.put(:repo, "b-org/fixture-repo")
      |> SourceRegistry.create_source()

    assert {:ok, stored} =
             Ingestion.ingest_all_and_store(github: StubFetcher, chunk_store: StubChunkStore)

    assert Enum.map(stored, fn %{document: document} -> document.metadata.source_ref end) == [
             "a-org/fixture-repo@v0.0.0-fixture:docs/http/http-spans.md",
             "a-org/fixture-repo@v0.0.0-fixture:docs/general/attributes.md",
             "b-org/fixture-repo@v0.0.0-fixture:docs/http/http-spans.md",
             "b-org/fixture-repo@v0.0.0-fixture:docs/general/attributes.md"
           ]
  end
end
