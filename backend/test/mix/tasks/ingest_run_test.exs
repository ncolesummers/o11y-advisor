defmodule Mix.Tasks.Ingest.RunTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Ingest.Run
  alias O11yAdvisor.Ingestion.Document

  defmodule FakeIngestion do
    def ingest_all(_opts) do
      [
        %Document{
          content: "# HTTP Spans\n",
          metadata: %{
            title: "HTTP Spans",
            version: "v1.29.0",
            license: "Apache-2.0",
            source_url:
              "https://github.com/open-telemetry/semantic-conventions/blob/v1.29.0/docs/http/http-spans.md"
          }
        }
      ]
    end
  end

  test "prints a per-document summary with license and version" do
    output =
      capture_io(fn ->
        assert :ok = Run.run([], ingestion: FakeIngestion, start_app?: false)
      end)

    assert output =~ "Ingested 1 document(s)"
    assert output =~ "HTTP Spans"
    assert output =~ "v1.29.0"
    assert output =~ "Apache-2.0"
  end

  test "rejects unknown options" do
    assert_raise Mix.Error, ~r/Invalid ingest.run option/, fn ->
      Run.run(["--unknown"], ingestion: FakeIngestion, start_app?: false)
    end
  end
end
