defmodule O11yAdvisor.Ingestion.GlobTest do
  use ExUnit.Case, async: true

  alias O11yAdvisor.Ingestion.Glob

  defp matches?(glob, path), do: Regex.match?(Glob.to_regex(glob), path)

  describe "to_regex/1 with docs/**/*.md" do
    test "matches a file directly in the base dir (zero intermediate dirs)" do
      assert matches?("docs/**/*.md", "docs/intro.md")
    end

    test "matches a deeply nested file" do
      assert matches?("docs/**/*.md", "docs/http/http-spans.md")
    end

    test "does not match files outside the base dir" do
      refute matches?("docs/**/*.md", "specification/intro.md")
    end

    test "does not match non-markdown files" do
      refute matches?("docs/**/*.md", "docs/http/example.yaml")
    end
  end

  describe "to_regex/1 with **/*.md" do
    test "matches top-level markdown" do
      assert matches?("**/*.md", "README.md")
    end

    test "matches nested markdown" do
      assert matches?("**/*.md", "guides/oncall/escalation.md")
    end

    test "does not match non-markdown" do
      refute matches?("**/*.md", "guides/oncall/diagram.png")
    end
  end

  describe "to_regex/1 segment semantics" do
    test "single * stays within a path segment" do
      assert matches?("docs/*.md", "docs/intro.md")
      refute matches?("docs/*.md", "docs/http/spans.md")
    end

    test "escapes regex metacharacters in literal segments" do
      assert matches?("specification/**/*.md", "specification/logs/data-model.md")
      refute matches?("specification/**/*.md", "specificationXlogs/data-model.md")
    end
  end
end
