defmodule O11yAdvisor.SourceRegistry.SourceTest do
  use O11yAdvisor.DataCase, async: true

  alias O11yAdvisor.SourceRegistry.Source

  @valid_attrs %{
    repo: "open-telemetry/opentelemetry-specification",
    path_glob: "specification/**/*.md",
    license: "Apache-2.0",
    version_pin: "v1.39.0",
    project: "OpenTelemetry",
    content_type: "specification"
  }

  test "changeset accepts an allowed license with all required fields" do
    changeset = Source.changeset(%Source{}, @valid_attrs)

    assert changeset.valid?
  end

  test "changeset rejects banned licenses" do
    changeset =
      Source.changeset(%Source{}, %{
        @valid_attrs
        | license: "CC BY-NC-ND 4.0"
      })

    refute changeset.valid?
    assert "is invalid" in errors_on(changeset).license
  end

  test "changeset requires registry fields" do
    changeset = Source.changeset(%Source{}, %{})

    assert %{repo: ["can't be blank"]} = errors_on(changeset)
    assert %{path_glob: ["can't be blank"]} = errors_on(changeset)
    assert %{license: ["can't be blank"]} = errors_on(changeset)
    assert %{version_pin: ["can't be blank"]} = errors_on(changeset)
  end

  test "changeset rejects default branch version pins" do
    changeset =
      Source.changeset(%Source{}, %{
        @valid_attrs
        | version_pin: "main"
      })

    refute changeset.valid?
    assert "must be an explicit git ref" in errors_on(changeset).version_pin
  end
end
