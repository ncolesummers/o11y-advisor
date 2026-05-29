defmodule Mix.Tasks.Eval.RunTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Eval.Run

  test "run/1 completes without error" do
    Run.run([])
  end
end
