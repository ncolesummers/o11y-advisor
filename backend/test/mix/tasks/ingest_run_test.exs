defmodule Mix.Tasks.Ingest.RunTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Ingest.Run

  defmodule FakeIngestion do
    def ingest_all_and_store(_opts) do
      {:ok,
       [
         %{
           document: %{
             metadata: %{
               title: "HTTP Spans",
               version: "v1.29.0",
               license: "Apache-2.0",
               source_url:
                 "https://github.com/open-telemetry/semantic-conventions/blob/v1.29.0/docs/http/http-spans.md"
             }
           },
           chunks: [%{}, %{}]
         }
       ]}
    end
  end

  defmodule FailingIngestion do
    def ingest_all_and_store(_opts) do
      {:error, :embedding_failed}
    end
  end

  test "prints a stored document summary with license and version" do
    output =
      capture_io(fn ->
        assert :ok = Run.run([], ingestion: FakeIngestion, start_app?: false)
      end)

    assert output =~ "Stored 1 document(s), 2 chunk(s)"
    assert output =~ "HTTP Spans"
    assert output =~ "v1.29.0"
    assert output =~ "Apache-2.0"
  end

  test "raises when ingestion storage fails" do
    assert_raise Mix.Error, ~r/ingest.run failed/, fn ->
      Run.run([], ingestion: FailingIngestion, start_app?: false)
    end
  end

  test "rejects unknown options" do
    assert_raise Mix.Error, ~r/Invalid ingest.run option/, fn ->
      Run.run(["--unknown"], ingestion: FakeIngestion, start_app?: false)
    end
  end
end
