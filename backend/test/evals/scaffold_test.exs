defmodule O11yAdvisor.Evals.ScaffoldTest do
  use ExUnit.Case, async: true

  alias O11yAdvisor.Evals.EvalCase
  alias O11yAdvisor.Evals.HardFail

  @tag :hard_fail
  test "seed eval cases load and validate against the PRD schema" do
    assert {:ok, [%EvalCase{} = eval_case]} = HardFail.load_and_validate_cases()
    assert eval_case.id == "eval-otel-fastapi-001"
  end

  @tag :hard_fail
  test "must_not_include checks catch forbidden answer text" do
    assert {:ok, [eval_case]} = HardFail.load_and_validate_cases()

    assert [
             %{
               case_id: "eval-otel-fastapi-001",
               check: :must_not_include,
               value: "vendor-specific requirement unless asked"
             }
           ] =
             HardFail.must_not_include_violations(
               eval_case,
               "This includes a vendor-specific requirement unless asked."
             )
  end

  @tag :hard_fail
  test "banned-source checks catch non-derivative citations" do
    citations = [
      %{
        "title" => "Banned source",
        "url" => "https://example.com/banned",
        "license" => "CC BY-NC-ND 4.0"
      }
    ]

    assert [
             %{
               check: :banned_source,
               title: "Banned source",
               url: "https://example.com/banned",
               license: "CC BY-NC-ND 4.0"
             }
           ] = HardFail.banned_source_violations(citations)
  end
end
