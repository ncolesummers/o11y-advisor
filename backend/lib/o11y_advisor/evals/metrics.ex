defmodule O11yAdvisor.Evals.Metrics do
  @moduledoc """
  Pure retrieval metric helpers used by the eval runner and tests.
  """

  alias O11yAdvisor.Evals.EvalCase

  @type case_result :: %{
          case_id: String.t(),
          recall: float(),
          required_recall: float(),
          passed?: boolean()
        }

  @spec empty_retrieval_report() :: map()
  def empty_retrieval_report do
    %{
      test_case_count: 0,
      passed: 0,
      failed: 0,
      average_recall: 0.0,
      results: []
    }
  end

  @spec retrieval_report([EvalCase.t()], map()) :: map()
  def retrieval_report([], _retrieved_sources_by_case), do: empty_retrieval_report()

  def retrieval_report(eval_cases, retrieved_sources_by_case) do
    results =
      Enum.map(eval_cases, fn %EvalCase{} = eval_case ->
        retrieved_sources =
          retrieved_sources_by_case
          |> Map.get(eval_case.id, [])
          |> Enum.take(eval_case.retrieval_k)

        recall = recall(eval_case.expected_sources, retrieved_sources)

        %{
          case_id: eval_case.id,
          recall: recall,
          required_recall: eval_case.required_recall,
          passed?: recall >= eval_case.required_recall
        }
      end)

    passed = Enum.count(results, & &1.passed?)

    %{
      test_case_count: length(results),
      passed: passed,
      failed: length(results) - passed,
      average_recall: average_recall(results),
      results: results
    }
  end

  @spec recall([String.t()], [String.t()]) :: float()
  def recall([], _retrieved_sources), do: 1.0

  def recall(expected_sources, retrieved_sources) do
    expected = MapSet.new(expected_sources, &normalize_source/1)
    retrieved = MapSet.new(retrieved_sources, &normalize_source/1)

    expected
    |> MapSet.intersection(retrieved)
    |> MapSet.size()
    |> Kernel./(MapSet.size(expected))
  end

  defp average_recall([]), do: 0.0

  defp average_recall(results) do
    total = Enum.reduce(results, 0.0, &(&1.recall + &2))
    total / length(results)
  end

  defp normalize_source(source), do: source |> to_string() |> String.downcase() |> String.trim()
end
