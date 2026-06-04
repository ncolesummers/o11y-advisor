defmodule O11yAdvisor.Evals.EvalCaseTest do
  use ExUnit.Case, async: true

  alias O11yAdvisor.Evals.EvalCase

  @valid_case %{
    "id" => "eval-otel-fastapi-001",
    "question" => "How should I instrument FastAPI?",
    "expected_topics" => ["FastAPI instrumentation"],
    "must_not_include" => ["vendor-specific requirement unless asked"],
    "source_requirements" => ["OpenTelemetry Python docs"],
    "expected_sources" => ["open-telemetry/opentelemetry-python"],
    "retrieval_k" => 5,
    "required_recall" => 0.8
  }

  test "builds a valid eval case from a PRD-shaped map" do
    assert {:ok, %EvalCase{} = eval_case} = EvalCase.from_map(@valid_case)
    assert eval_case.id == "eval-otel-fastapi-001"
    assert eval_case.retrieval_k == 5
    assert eval_case.required_recall == 0.8
  end

  test "rejects missing and invalid schema fields" do
    invalid_case =
      @valid_case
      |> Map.delete("expected_sources")
      |> Map.put("retrieval_k", 0)
      |> Map.put("required_recall", 1.5)

    assert {:error, errors} = EvalCase.from_map(invalid_case)
    assert Enum.any?(errors, &String.contains?(&1, "expected_sources"))
    assert Enum.any?(errors, &String.contains?(&1, "retrieval_k"))
    assert Enum.any?(errors, &String.contains?(&1, "required_recall"))
  end

  test "rejects empty or blank expected sources" do
    assert {:error, empty_errors} =
             @valid_case
             |> Map.put("expected_sources", [])
             |> EvalCase.from_map()

    assert Enum.any?(empty_errors, &String.contains?(&1, "at least one source"))

    assert {:error, blank_errors} =
             @valid_case
             |> Map.put("expected_sources", [" "])
             |> EvalCase.from_map()

    assert Enum.any?(blank_errors, &String.contains?(&1, "non-empty strings"))
  end

  @tag :tmp_dir
  test "loads eval cases from a directory", %{tmp_dir: tmp_dir} do
    File.write!(Path.join(tmp_dir, "seed.json"), Jason.encode!([@valid_case]))

    assert {:ok, [%EvalCase{id: "eval-otel-fastapi-001"}]} = EvalCase.load_dir(tmp_dir)
  end
end
