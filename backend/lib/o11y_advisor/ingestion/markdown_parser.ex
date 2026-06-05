defmodule O11yAdvisor.Ingestion.MarkdownParser do
  @moduledoc """
  Turns raw Markdown fetched from a registered source into an
  `O11yAdvisor.Ingestion.Document` with the PRD §8 metadata stamped on.

  Pure: no network, no DB. The `version` metadata is the source's pinned ref
  (ADR-0003), and `license`/`project`/`content_type` are carried from the
  registry onto every document.

  Title extraction is a lightweight scan for the first level-one ATX heading
  (`# Heading`). A `# ` inside a fenced code block or front-matter could be a
  false positive; that is an accepted limitation at this scope.
  """

  alias O11yAdvisor.Ingestion.Document
  alias O11yAdvisor.SourceRegistry.Source

  @h1 ~r/^#[ \t]+(.+?)[ \t]*$/m

  @spec parse(String.t(), String.t(), Source.t()) :: Document.t()
  def parse(raw, repo_path, %Source{} = source) when is_binary(raw) and is_binary(repo_path) do
    metadata = %{
      source_url: "https://github.com/#{source.repo}/blob/#{source.version_pin}/#{repo_path}",
      title: title(raw, repo_path),
      project: source.project,
      content_type: source.content_type,
      license: source.license,
      retrieved_at: Date.utc_today() |> Date.to_iso8601(),
      version: source.version_pin,
      source_ref: source_ref(source, repo_path),
      section_path: section_path(repo_path)
    }

    %Document{content: raw, metadata: metadata}
  end

  defp title(raw, repo_path) do
    case Regex.run(@h1, raw, capture: :all_but_first) do
      [heading] -> String.trim(heading)
      nil -> Path.rootname(Path.basename(repo_path))
    end
  end

  defp section_path(repo_path) do
    repo_path
    |> Path.split()
    |> Enum.drop(-1)
  end

  defp source_ref(source, repo_path), do: "#{source.repo}@#{source.version_pin}:#{repo_path}"
end
