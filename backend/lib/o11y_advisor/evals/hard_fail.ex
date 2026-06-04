defmodule O11yAdvisor.Evals.HardFail do
  @moduledoc """
  Deterministic hard-fail checks for eval cases and outputs.
  """

  alias O11yAdvisor.Evals.EvalCase

  @banned_license_patterns [
    "CC BY-NC-ND",
    "CC-BY-NC-ND",
    "CC BY-NC-ND 4.0",
    "CC-BY-NC-ND-4.0"
  ]

  @spec load_and_validate_cases(String.t()) :: {:ok, [EvalCase.t()]} | {:error, [String.t()]}
  def load_and_validate_cases(path \\ EvalCase.default_cases_path()), do: EvalCase.load_dir(path)

  @spec must_not_include_violations(EvalCase.t(), String.t() | nil) :: [map()]
  def must_not_include_violations(%EvalCase{} = eval_case, output) do
    normalized_output = normalize_text(output || "")

    eval_case.must_not_include
    |> Enum.filter(fn phrase ->
      String.trim(phrase) != "" and String.contains?(normalized_output, normalize_text(phrase))
    end)
    |> Enum.map(fn phrase ->
      %{case_id: eval_case.id, check: :must_not_include, value: phrase}
    end)
  end

  @spec banned_source_violations([map()]) :: [map()]
  def banned_source_violations(citations) when is_list(citations) do
    Enum.flat_map(citations, fn citation ->
      license = citation_value(citation, "license")

      if banned_license?(license) do
        [
          %{
            check: :banned_source,
            title: citation_value(citation, "title"),
            url: citation_value(citation, "url"),
            license: license
          }
        ]
      else
        []
      end
    end)
  end

  def banned_source_violations(_citations),
    do: [%{check: :banned_source, error: "citations must be a list"}]

  @spec banned_license?(String.t() | nil) :: boolean()
  def banned_license?(nil), do: false

  def banned_license?(license) when is_binary(license) do
    normalized_license = normalize_license(license)

    Enum.any?(@banned_license_patterns, fn banned ->
      String.contains?(normalized_license, normalize_license(banned))
    end)
  end

  def banned_license?(_license), do: false

  defp citation_value(citation, key) when is_map(citation) do
    Map.get(citation, key) || atom_citation_value(citation, key)
  end

  defp citation_value(_citation, _key), do: nil

  defp atom_citation_value(citation, "license"), do: Map.get(citation, :license)
  defp atom_citation_value(citation, "title"), do: Map.get(citation, :title)
  defp atom_citation_value(citation, "url"), do: Map.get(citation, :url)
  defp atom_citation_value(_citation, _key), do: nil

  defp normalize_text(text), do: text |> String.downcase() |> String.trim()

  defp normalize_license(license) do
    license
    |> String.upcase()
    |> String.replace(~r/[^A-Z0-9]+/, "")
  end
end
