defmodule O11yAdvisor.Repo.Migrations.AddMetadataToSourceRegistryEntries do
  use Ecto.Migration

  def change do
    alter table(:source_registry_entries) do
      add :project, :string
      add :content_type, :string
    end
  end
end
