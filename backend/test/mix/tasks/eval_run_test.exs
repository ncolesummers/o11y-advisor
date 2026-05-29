defmodule Mix.Tasks.Eval.RunTest do
  use ExUnit.Case, async: true

  test "run/1 completes without error" do
    Mix.Tasks.Eval.Run.run([])
  end
end
