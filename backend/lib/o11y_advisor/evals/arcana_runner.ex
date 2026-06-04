defmodule O11yAdvisor.Evals.ArcanaRunner do
  @moduledoc """
  Adapter around Arcana's retrieval evaluation API.
  """

  alias O11yAdvisor.Evals.Metrics

  @spec run(keyword()) :: {:ok, map()} | {:error, term()}
  def run(opts \\ []) do
    evaluation_module = Keyword.get(opts, :evaluation_module, Arcana.Evaluation)
    repo = Keyword.get(opts, :repo, O11yAdvisor.Repo)
    mode = Keyword.get(opts, :mode, :hybrid)

    with :ok <- ensure_arcana_loaded(evaluation_module),
         {:ok, test_case_count} <- count_test_cases(evaluation_module, repo) do
      run_if_cases_exist(evaluation_module, repo, mode, test_case_count)
    end
  end

  defp ensure_arcana_loaded(evaluation_module) do
    if Code.ensure_loaded?(evaluation_module) do
      :ok
    else
      {:error, :arcana_evaluation_unavailable}
    end
  end

  defp count_test_cases(evaluation_module, repo) do
    if function_exported?(evaluation_module, :count_test_cases, 1) do
      case evaluation_module.count_test_cases(repo: repo) do
        {:ok, count} when is_integer(count) -> {:ok, count}
        count when is_integer(count) -> {:ok, count}
        {:error, reason} -> {:error, reason}
      end
    else
      {:ok, 0}
    end
  rescue
    error -> {:error, error}
  end

  defp run_if_cases_exist(_evaluation_module, _repo, mode, 0) do
    {:ok,
     %{
       tool: :arcana,
       mode: mode,
       status: :empty,
       test_case_count: 0,
       metrics: Metrics.empty_retrieval_report()
     }}
  end

  defp run_if_cases_exist(evaluation_module, repo, mode, test_case_count) do
    case evaluation_module.run(repo: repo, mode: mode) do
      {:ok, run} ->
        {:ok,
         %{
           tool: :arcana,
           mode: mode,
           status: :ok,
           test_case_count: test_case_count,
           metrics: Map.get(run, :metrics, %{})
         }}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    error -> {:error, error}
  end
end
