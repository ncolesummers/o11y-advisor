defmodule O11yAdvisor.Ingestion.Document do
  @moduledoc """
  A fetched-and-parsed source document, ready for chunking and pgvector storage.

  `content` is the raw Markdown. `metadata` carries the PRD §8 fields:
  `source_url`, `title`, `project`, `content_type`, `license`, `retrieved_at`,
  `version`, and `section_path`.

  This is the in-memory handoff between fetch/parse and chunk storage.
  """

  @enforce_keys [:content, :metadata]
  defstruct [:content, :metadata]

  @type t :: %__MODULE__{content: String.t(), metadata: map()}
end
