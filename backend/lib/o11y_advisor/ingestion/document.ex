defmodule O11yAdvisor.Ingestion.Document do
  @moduledoc """
  A fetched-and-parsed source document, ready for chunking (#18).

  `content` is the raw Markdown. `metadata` carries the PRD §8 fields:
  `source_url`, `title`, `project`, `content_type`, `license`, `retrieved_at`,
  `version`, and `section_path`.

  This is an in-memory value only — #17 persists nothing. Downstream chunking
  hands `content` + `metadata` to `Arcana.Ingest.ingest/2`.
  """

  @enforce_keys [:content, :metadata]
  defstruct [:content, :metadata]

  @type t :: %__MODULE__{content: String.t(), metadata: map()}
end
