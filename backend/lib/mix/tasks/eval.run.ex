defmodule Mix.Tasks.Eval.Run do
  use Mix.Task

  alias O11yAdvisor.Evals.Runner

  @shortdoc "Run the evaluation suite"

  @moduledoc """
  Runs the backend evaluation harness.

      mix eval.run
      mix eval.run --quick

  `--quick` runs retrieval evals only. The default mode runs retrieval evals
  plus scaffolded answer-quality reporting.
  """

  @spec run([String.t()]) :: :ok
  def run(args), do: run(args, runner: Runner, start_app?: true)

  @spec run([String.t()], keyword()) :: :ok
  def run(args, opts) do
    {parsed, remaining, invalid} = OptionParser.parse(args, strict: [quick: :boolean])

    cond do
      invalid != [] ->
        Mix.raise("Invalid eval.run option(s): #{format_invalid_options(invalid)}")

      remaining != [] ->
        Mix.raise("Unexpected eval.run argument(s): #{Enum.join(remaining, " ")}")

      true ->
        execute(parsed, opts)
    end
  end

  defp execute(parsed, opts) do
    if Keyword.get(opts, :start_app?, true), do: Mix.Task.run("app.start")

    mode = if Keyword.get(parsed, :quick, false), do: :quick, else: :full
    runner = Keyword.fetch!(opts, :runner)

    case runner.run(mode: mode) do
      {:ok, report} ->
        print_report(report)
        :ok

      {:error, reason} ->
        Mix.raise("Evaluation run failed: #{format_reason(reason)}")
    end
  end

  defp print_report(report) do
    Mix.shell().info("Evaluation mode: #{report.mode}")
    Mix.shell().info("Eval case schemas loaded: #{report.case_schema_count}")

    print_retrieval_report(report.retrieval)

    if Map.has_key?(report, :answer_quality) do
      Mix.shell().info("Answer quality: #{report.answer_quality.status}")
      Mix.shell().info(report.answer_quality.message)
    end
  end

  defp print_retrieval_report(%{status: :empty, metrics: metrics}) do
    Mix.shell().info("Retrieval evals: 0 cases")
    Mix.shell().info("Average recall: #{format_float(metrics.average_recall)}")
  end

  defp print_retrieval_report(%{status: status, metrics: metrics}) do
    Mix.shell().info("Retrieval evals: #{retrieval_case_count(metrics)} cases")
    Mix.shell().info("Retrieval status: #{status}")
    print_metric_lines(metrics)
  end

  defp print_retrieval_report(%{status: status, test_case_count: test_case_count}) do
    Mix.shell().info("Retrieval evals: #{test_case_count} cases")
    Mix.shell().info("Retrieval status: #{status}")
  end

  defp retrieval_case_count(metrics) do
    Map.get(metrics, :test_case_count, Map.get(metrics, "test_case_count", "unknown"))
  end

  defp print_metric_lines(metrics) do
    metrics
    |> Map.drop([:test_case_count, "test_case_count"])
    |> Enum.sort_by(fn {metric, _value} -> metric end)
    |> Enum.each(fn {metric, value} ->
      Mix.shell().info("#{format_metric_name(metric)}: #{format_float(value)}")
    end)
  end

  defp format_metric_name(metric) when is_atom(metric) do
    metric
    |> Atom.to_string()
    |> format_metric_name()
  end

  defp format_metric_name(metric) when is_binary(metric) do
    metric
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_invalid_options(invalid) do
    Enum.map_join(invalid, ", ", fn {option, value} -> "#{option}=#{value}" end)
  end

  defp format_reason(%{__exception__: true} = reason), do: Exception.message(reason)
  defp format_reason(%{message: message}), do: message
  defp format_reason(reason), do: inspect(reason)

  defp format_float(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 3)
  defp format_float(value), do: to_string(value)
end
