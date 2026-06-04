defmodule Mix.Tasks.Eval.RunTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Eval.Run
  alias O11yAdvisor.Evals.Metrics

  defmodule FakeRunner do
    def run(opts) do
      send(self(), {:eval_run_opts, opts})

      report = %{
        mode: opts[:mode],
        case_schema_count: 1,
        retrieval: %{
          tool: :arcana,
          mode: :hybrid,
          status: :empty,
          metrics: Metrics.empty_retrieval_report()
        }
      }

      report =
        if opts[:mode] == :full do
          Map.put(report, :answer_quality, %{
            tool: :tribunal,
            status: :scaffolded,
            test_case_count: 0,
            message: "No answer-quality provider configured yet."
          })
        else
          report
        end

      {:ok, report}
    end
  end

  defmodule NonEmptyRunner do
    def run(opts) do
      {:ok,
       %{
         mode: opts[:mode],
         case_schema_count: 1,
         retrieval: %{
           tool: :arcana,
           mode: :hybrid,
           status: :ok,
           test_case_count: 2,
           metrics: %{average_recall: 0.75, hit_rate: 1.0}
         }
       }}
    end
  end

  test "passes quick mode to the eval runner" do
    output =
      capture_io(fn ->
        assert :ok = Run.run(["--quick"], runner: FakeRunner, start_app?: false)
      end)

    assert_receive {:eval_run_opts, mode: :quick}
    assert output =~ "Evaluation mode: quick"
    assert output =~ "Retrieval evals: 0 cases"
  end

  test "defaults to full mode" do
    output =
      capture_io(fn ->
        assert :ok = Run.run([], runner: FakeRunner, start_app?: false)
      end)

    assert_receive {:eval_run_opts, mode: :full}
    assert output =~ "Evaluation mode: full"
    assert output =~ "Answer quality: scaffolded"
  end

  test "prints available metrics for non-empty retrieval reports" do
    output =
      capture_io(fn ->
        assert :ok = Run.run(["--quick"], runner: NonEmptyRunner, start_app?: false)
      end)

    assert output =~ "Retrieval evals: 2 cases"
    assert output =~ "Average recall: 0.750"
    assert output =~ "Hit rate: 1.000"
  end

  test "rejects unknown options" do
    assert_raise Mix.Error, ~r/Invalid eval.run option/, fn ->
      Run.run(["--unknown"], runner: FakeRunner, start_app?: false)
    end
  end
end
