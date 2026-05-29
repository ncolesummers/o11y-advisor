defmodule Mix.Tasks.Eval.Run do
  use Mix.Task

  @shortdoc "Run evaluation suite (stub)"

  @moduledoc """
  Stub eval task — evals are configured in a later milestone.
  """

  def run(_args), do: Mix.shell().info("No evals configured yet.")
end
