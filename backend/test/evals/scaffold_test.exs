defmodule O11yAdvisor.Evals.ScaffoldTest do
  use ExUnit.Case, async: true

  @tag :hard_fail
  test "scaffold hard_fail gate" do
    assert true
  end
end
