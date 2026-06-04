defmodule O11yAdvisor.Evals.MetricsTest do
  use ExUnit.Case, async: true

  alias O11yAdvisor.Evals.EvalCase
  alias O11yAdvisor.Evals.Metrics

  test "computes recall from expected and retrieved sources" do
    assert Metrics.recall(["a", "b"], ["b", "c"]) == 0.5
    assert Metrics.recall(["a"], ["A"]) == 1.0
  end

  test "builds retrieval report with per-case pass status" do
    eval_case = %EvalCase{
      id: "eval-1",
      question: "question",
      expected_topics: [],
      must_not_include: [],
      source_requirements: [],
      expected_sources: ["source-a", "source-b"],
      retrieval_k: 2,
      required_recall: 0.5
    }

    report = Metrics.retrieval_report([eval_case], %{"eval-1" => ["source-a", "source-c"]})

    assert report.test_case_count == 1
    assert report.passed == 1
    assert report.failed == 0
    assert report.average_recall == 0.5
  end
end
