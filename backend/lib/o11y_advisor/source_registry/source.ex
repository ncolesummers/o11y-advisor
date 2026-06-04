defmodule O11yAdvisor.SourceRegistry.Source do
  use Ecto.Schema

  import Ecto.Changeset

  @allowed_licenses [
    "Apache-2.0",
    "CC-BY-4.0",
    "CC BY 4.0"
  ]
  @default_refs ~w(main master head latest refs/heads/main refs/heads/master origin/main origin/master)
  @content_types ["specification", "docs", "query reference"]
  @required_fields [:repo, :path_glob, :license, :version_pin, :project, :content_type]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "source_registry_entries" do
    field :repo, :string
    field :path_glob, :string
    field :license, :string
    field :version_pin, :string
    field :project, :string
    field :content_type, :string

    timestamps()
  end

  @doc false
  def changeset(source, attrs) do
    source
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_format(:repo, ~r/^[^\/\s]+\/[^\/\s]+$/,
      message: "must be an owner/repo GitHub repository"
    )
    |> validate_inclusion(:license, @allowed_licenses)
    |> validate_inclusion(:content_type, @content_types)
    |> validate_change(:version_pin, &validate_explicit_ref/2)
    |> unique_constraint([:repo, :path_glob, :version_pin])
  end

  def allowed_licenses, do: @allowed_licenses

  def content_types, do: @content_types

  defp validate_explicit_ref(:version_pin, version_pin) do
    normalized_ref = version_pin |> String.trim() |> String.downcase()

    if normalized_ref in @default_refs do
      [version_pin: "must be an explicit git ref"]
    else
      []
    end
  end
end
