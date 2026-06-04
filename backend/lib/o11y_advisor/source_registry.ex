defmodule O11yAdvisor.SourceRegistry do
  @moduledoc """
  Source registry entries that drive knowledge-base ingestion.
  """

  import Ecto.Query, warn: false

  alias O11yAdvisor.Repo
  alias O11yAdvisor.SourceRegistry.Source

  @seed_sources [
    %{
      repo: "open-telemetry/semantic-conventions",
      path_glob: "docs/**/*.md",
      license: "Apache-2.0",
      version_pin: "v1.29.0",
      project: "OpenTelemetry",
      content_type: "specification"
    },
    %{
      repo: "open-telemetry/opentelemetry-specification",
      path_glob: "specification/**/*.md",
      license: "Apache-2.0",
      version_pin: "v1.39.0",
      project: "OpenTelemetry",
      content_type: "specification"
    },
    %{
      repo: "PagerDuty/incident-response-docs",
      path_glob: "**/*.md",
      license: "Apache-2.0",
      version_pin: "6353d89dff2f53de39216789393fd77f8026b47e",
      project: "PagerDuty",
      content_type: "docs"
    },
    %{
      repo: "OpenSLO/oslo",
      path_glob: "**/*.md",
      license: "Apache-2.0",
      version_pin: "v0.13.0",
      project: "OpenSLO",
      content_type: "specification"
    }
  ]

  def list_sources do
    Source
    |> order_by([source], asc: source.repo, asc: source.path_glob, asc: source.version_pin)
    |> Repo.all()
  end

  def create_source(attrs) do
    %Source{}
    |> Source.changeset(attrs)
    |> Repo.insert()
  end

  def seed_sources! do
    Enum.each(@seed_sources, &upsert_source!/1)
  end

  defp upsert_source!(attrs) do
    %Source{}
    |> Source.changeset(attrs)
    |> Repo.insert!(
      on_conflict: {:replace, [:license, :project, :content_type, :updated_at]},
      conflict_target: [:repo, :path_glob, :version_pin]
    )
  end
end
