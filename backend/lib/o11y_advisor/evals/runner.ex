defmodule O11yAdvisor.Evals.Runner do
  @moduledoc """
  Coordinates the backend evaluation harness.
  """

  alias O11yAdvisor.Evals.ArcanaRunner
  alias O11yAdvisor.Evals.EvalCase

  @spec run(keyword()) :: {:ok, map()} | {:error, term()}
  def run(opts \\ []) do
    mode = Keyword.get(opts, :mode, :full)
    cases_path = Keyword.get(opts, :cases_path, EvalCase.default_cases_path())
    arcana_runner = Keyword.get(opts, :arcana_runner, ArcanaRunner)

    with {:ok, cases} <- EvalCase.load_dir(cases_path),
         {:ok, retrieval_report} <- arcana_runner.run(repo: O11yAdvisor.Repo, mode: :hybrid) do
      report =
        %{
          mode: mode,
          case_schema_count: length(cases),
          retrieval: retrieval_report
        }
        |> maybe_add_answer_quality(mode)

      {:ok, report}
    end
  end

  defp maybe_add_answer_quality(report, :quick), do: report

  defp maybe_add_answer_quality(report, :full) do
    Map.put(report, :answer_quality, %{
      tool: :tribunal,
      status: tribunal_status(),
      test_case_count: 0,
      message: "No answer-quality provider configured yet."
    })
  end

  defp maybe_add_answer_quality(report, _mode), do: report

  defp tribunal_status do
    if Code.ensure_loaded?(Tribunal) do
      :scaffolded
    else
      :unavailable
    end
  end
end
