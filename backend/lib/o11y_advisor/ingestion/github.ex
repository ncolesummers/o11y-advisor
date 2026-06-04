defmodule O11yAdvisor.Ingestion.GitHub do
  @moduledoc """
  Fetches the Markdown files matching a source's `path_glob` at its pinned ref.

  Lists the repository tree once via the Git Trees API, filters blob paths by
  the glob, then fetches each match's raw content. Honors an optional
  `GITHUB_TOKEN`/`GH_TOKEN` for a higher API rate limit (5000/hr vs 60/hr).

  This is the only module in the ingestion path that touches the network.
  """

  require Logger

  alias O11yAdvisor.Ingestion.Glob
  alias O11yAdvisor.SourceRegistry.Source

  @api_host "https://api.github.com"
  @raw_host "https://raw.githubusercontent.com"

  @type file :: {path :: String.t(), content :: String.t()}

  @spec fetch_matching(Source.t()) :: {:ok, [file()]} | {:error, term()}
  def fetch_matching(%Source{} = source) do
    with {:ok, tree} <- fetch_tree(source.repo, source.version_pin) do
      paths = matching_paths(tree, source.path_glob)
      fetch_files(source.repo, source.version_pin, paths)
    end
  end

  defp fetch_tree(repo, ref) do
    url = "#{@api_host}/repos/#{repo}/git/trees/#{ref}"

    case Req.get(url, params: [recursive: 1], headers: headers()) do
      {:ok, %{status: 200, body: %{"tree" => tree} = body}} ->
        maybe_warn_truncated(body, repo, ref)
        {:ok, tree}

      {:ok, %{status: status, body: body}} ->
        {:error, {:github_api, status, body}}

      {:error, reason} ->
        {:error, {:github_api, reason}}
    end
  end

  @doc false
  # Public only so the glob-meets-tree filtering seam is unit-testable without HTTP.
  @spec matching_paths([map()], String.t()) :: [String.t()]
  def matching_paths(tree, glob) do
    regex = Glob.to_regex(glob)

    for %{"type" => "blob", "path" => path} <- tree, Regex.match?(regex, path), do: path
  end

  defp fetch_files(repo, ref, paths) do
    paths
    |> Enum.reduce_while({:ok, []}, fn path, {:ok, acc} ->
      case fetch_raw(repo, ref, path) do
        {:ok, content} -> {:cont, {:ok, [{path, content} | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, files} -> {:ok, Enum.reverse(files)}
      error -> error
    end
  end

  defp fetch_raw(repo, ref, path) do
    url = "#{@raw_host}/#{repo}/#{ref}/#{path}"

    case Req.get(url, headers: headers()) do
      {:ok, %{status: 200, body: body}} -> {:ok, to_string(body)}
      {:ok, %{status: status}} -> {:error, {:raw_fetch, status, path}}
      {:error, reason} -> {:error, {:raw_fetch, reason, path}}
    end
  end

  defp headers do
    base = [{"accept", "application/vnd.github+json"}]

    case token() do
      nil -> base
      token -> [{"authorization", "Bearer #{token}"} | base]
    end
  end

  defp token, do: System.get_env("GITHUB_TOKEN") || System.get_env("GH_TOKEN")

  defp maybe_warn_truncated(%{"truncated" => true}, repo, ref) do
    Logger.warning("GitHub tree truncated for #{repo}@#{ref}; some files may be missing")
  end

  defp maybe_warn_truncated(_body, _repo, _ref), do: :ok
end
