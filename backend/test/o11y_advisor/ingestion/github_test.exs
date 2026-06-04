defmodule O11yAdvisor.Ingestion.GitHubTest do
  use ExUnit.Case, async: true

  alias O11yAdvisor.Ingestion.GitHub

  @tree [
    %{"type" => "blob", "path" => "docs/http/http-spans.md"},
    %{"type" => "blob", "path" => "docs/general/attributes.md"},
    %{"type" => "blob", "path" => "docs/http/example.yaml"},
    %{"type" => "tree", "path" => "docs/http"},
    %{"type" => "blob", "path" => "README.md"}
  ]

  test "matching_paths/2 keeps only blobs whose path matches the glob" do
    assert GitHub.matching_paths(@tree, "docs/**/*.md") == [
             "docs/http/http-spans.md",
             "docs/general/attributes.md"
           ]
  end

  test "matching_paths/2 excludes tree entries and non-matching extensions" do
    refute "docs/http" in GitHub.matching_paths(@tree, "docs/**/*.md")
    refute "docs/http/example.yaml" in GitHub.matching_paths(@tree, "docs/**/*.md")
  end

  test "matching_paths/2 with **/*.md matches top-level files too" do
    assert "README.md" in GitHub.matching_paths(@tree, "**/*.md")
  end
end
