defmodule O11yAdvisor.Evals.RunnerTest do
  use ExUnit.Case, async: true

  alias O11yAdvisor.Evals.Metrics
  alias O11yAdvisor.Evals.Runner

  defmodule EmptyArcanaRunner do
    def run(opts) do
      send(self(), {:arcana_runner_opts, opts})

      {:ok,
       %{
         tool: :arcana,
         mode: opts[:mode],
         status: :empty,
         metrics: Metrics.empty_retrieval_report()
       }}
    end
  end

  test "quick mode returns retrieval report without answer-quality scaffold" do
    assert {:ok, report} =
             Runner.run(
               mode: :quick,
               cases_path: "test/evals/cases",
               arcana_runner: EmptyArcanaRunner
             )

    assert_receive {:arcana_runner_opts, opts}
    assert opts[:mode] == :hybrid
    assert report.mode == :quick
    assert report.case_schema_count == 1
    refute Map.has_key?(report, :answer_quality)
  end

  test "full mode includes scaffolded Tribunal answer-quality report" do
    assert {:ok, report} =
             Runner.run(
               mode: :full,
               cases_path: "test/evals/cases",
               arcana_runner: EmptyArcanaRunner
             )

    assert report.mode == :full
    assert report.answer_quality.tool == :tribunal
    assert report.answer_quality.test_case_count == 0
  end
end
