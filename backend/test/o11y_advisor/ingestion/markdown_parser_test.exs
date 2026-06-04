defmodule O11yAdvisor.Ingestion.MarkdownParserTest do
  use ExUnit.Case, async: true

  alias O11yAdvisor.Ingestion.Document
  alias O11yAdvisor.Ingestion.MarkdownParser
  alias O11yAdvisor.SourceRegistry.Source

  @source %Source{
    repo: "open-telemetry/semantic-conventions",
    path_glob: "docs/**/*.md",
    license: "Apache-2.0",
    version_pin: "v1.29.0",
    project: "OpenTelemetry",
    content_type: "specification"
  }

  defp fixture(name) do
    File.read!(Path.join([__DIR__, "..", "..", "fixtures", "markdown", name]))
  end

  test "parses the first H1 as the title" do
    raw = fixture("with_h1.md")

    %Document{metadata: metadata} = MarkdownParser.parse(raw, "docs/http/http-spans.md", @source)

    assert metadata.title == "Real Title"
  end

  test "falls back to the filename (no extension) when there is no H1" do
    raw = fixture("no_h1.md")

    %Document{metadata: metadata} = MarkdownParser.parse(raw, "docs/http/http-spans.md", @source)

    assert metadata.title == "http-spans"
  end

  test "derives section_path from the directory segments" do
    %Document{metadata: metadata} =
      MarkdownParser.parse("# x", "docs/http/http-spans.md", @source)

    assert metadata.section_path == ["docs", "http"]
  end

  test "section_path is empty for a top-level file" do
    %Document{metadata: metadata} = MarkdownParser.parse("# x", "README.md", @source)

    assert metadata.section_path == []
  end

  test "stamps registry metadata and the pinned version onto the document" do
    raw = fixture("with_h1.md")

    %Document{content: content, metadata: metadata} =
      MarkdownParser.parse(raw, "docs/http/http-spans.md", @source)

    assert content == raw
    assert metadata.license == "Apache-2.0"
    assert metadata.version == "v1.29.0"
    assert metadata.project == "OpenTelemetry"
    assert metadata.content_type == "specification"

    assert metadata.source_url ==
             "https://github.com/open-telemetry/semantic-conventions/blob/v1.29.0/docs/http/http-spans.md"

    assert metadata.retrieved_at == Date.utc_today() |> Date.to_iso8601()
  end
end
