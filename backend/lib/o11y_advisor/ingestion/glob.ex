defmodule O11yAdvisor.Ingestion.Glob do
  @moduledoc """
  Translates source-registry `path_glob` patterns into anchored regexes for
  filtering a repository's file tree.

  Supports the glob subset used by the registry:

    * `**` — zero or more path segments (so `docs/**/*.md` matches both
      `docs/a.md` and `docs/a/b/c.md`)
    * `*`  — zero or more characters within a single segment (never crosses `/`)
    * `?`  — exactly one character within a single segment

  All other characters are matched literally (regex metacharacters escaped).
  """

  @doc """
  Compiles a glob into an anchored `Regex`. Raises on an invalid pattern.
  """
  @spec to_regex(String.t()) :: Regex.t()
  def to_regex(glob) when is_binary(glob) do
    Regex.compile!("^" <> translate(glob, "") <> "$")
  end

  defp translate("", acc), do: acc
  defp translate("**/" <> rest, acc), do: translate(rest, acc <> "(?:[^/]*/)*")
  defp translate("**" <> rest, acc), do: translate(rest, acc <> ".*")
  defp translate("*" <> rest, acc), do: translate(rest, acc <> "[^/]*")
  defp translate("?" <> rest, acc), do: translate(rest, acc <> "[^/]")

  defp translate(<<char::utf8, rest::binary>>, acc) do
    translate(rest, acc <> Regex.escape(<<char::utf8>>))
  end
end
