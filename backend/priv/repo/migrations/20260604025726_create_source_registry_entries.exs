defmodule O11yAdvisor.Repo.Migrations.CreateSourceRegistryEntries do
  use Ecto.Migration

  def change do
    create table(:source_registry_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :repo, :string, null: false
      add :path_glob, :string, null: false
      add :license, :string, null: false
      add :version_pin, :string, null: false

      timestamps()
    end

    create unique_index(:source_registry_entries, [:repo, :path_glob, :version_pin])
  end
end
