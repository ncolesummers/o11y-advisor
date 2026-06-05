defmodule O11yAdvisor.Repo.Migrations.UpdateArcanaEmbeddingDimensions do
  use Ecto.Migration

  def up do
    execute "DROP INDEX IF EXISTS arcana_chunks_embedding_idx"

    alter table(:arcana_chunks) do
      modify :embedding, :vector, size: 768, null: false
    end

    execute """
    CREATE INDEX arcana_chunks_embedding_idx ON arcana_chunks
    USING hnsw (embedding vector_cosine_ops)
    """
  end

  def down do
    execute "DROP INDEX IF EXISTS arcana_chunks_embedding_idx"

    alter table(:arcana_chunks) do
      modify :embedding, :vector, size: 384, null: false
    end

    execute """
    CREATE INDEX arcana_chunks_embedding_idx ON arcana_chunks
    USING hnsw (embedding vector_cosine_ops)
    """
  end
end
