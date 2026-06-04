defmodule O11yAdvisor.SourceRegistryTest do
  use O11yAdvisor.DataCase, async: false

  alias O11yAdvisor.SourceRegistry
  alias O11yAdvisor.SourceRegistry.Source

  @valid_attrs %{
    repo: "open-telemetry/opentelemetry-specification",
    path_glob: "specification/**/*.md",
    license: "Apache-2.0",
    version_pin: "v1.39.0",
    project: "OpenTelemetry",
    content_type: "specification"
  }

  test "create_source/1 persists valid registry entries" do
    assert {:ok, %Source{} = source} = SourceRegistry.create_source(@valid_attrs)

    assert source.repo == "open-telemetry/opentelemetry-specification"
    assert source.path_glob == "specification/**/*.md"
    assert source.license == "Apache-2.0"
    assert source.version_pin == "v1.39.0"
  end

  test "seed_sources!/0 loads the initial registry entries" do
    SourceRegistry.seed_sources!()

    assert %Source{license: "Apache-2.0", version_pin: "v1.29.0"} =
             Repo.get_by!(Source, repo: "open-telemetry/semantic-conventions")

    assert %Source{license: "Apache-2.0", version_pin: "v1.39.0"} =
             Repo.get_by!(Source, repo: "open-telemetry/opentelemetry-specification")

    assert %Source{
             license: "Apache-2.0",
             version_pin: "6353d89dff2f53de39216789393fd77f8026b47e"
           } =
             Repo.get_by!(Source, repo: "PagerDuty/incident-response-docs")

    assert %Source{license: "Apache-2.0", version_pin: "v0.13.0"} =
             Repo.get_by!(Source, repo: "OpenSLO/oslo")
  end
end
