defmodule O11yAdvisor.Evals.EvalCase do
  @moduledoc """
  Loads and validates PRD-shaped eval cases.
  """

  @required_string_fields ~w(id question)
  @required_string_list_fields ~w(expected_topics must_not_include source_requirements expected_sources)
  @required_number_fields ~w(retrieval_k required_recall)
  @required_fields @required_string_fields ++
                     @required_string_list_fields ++ @required_number_fields

  @enforce_keys [
    :id,
    :question,
    :expected_topics,
    :must_not_include,
    :source_requirements,
    :expected_sources,
    :retrieval_k,
    :required_recall
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          id: String.t(),
          question: String.t(),
          expected_topics: [String.t()],
          must_not_include: [String.t()],
          source_requirements: [String.t()],
          expected_sources: [String.t()],
          retrieval_k: pos_integer(),
          required_recall: float()
        }

  @spec default_cases_path() :: String.t()
  def default_cases_path do
    :o11y_advisor
    |> Application.get_env(:evals, [])
    |> Keyword.get(:cases_path, "test/evals/cases")
  end

  @spec load_dir(String.t()) :: {:ok, [t()]} | {:error, [String.t()]}
  def load_dir(path \\ default_cases_path()) do
    path
    |> Path.join("*.json")
    |> Path.wildcard()
    |> Enum.sort()
    |> load_files()
  end

  @spec load_file(String.t()) :: {:ok, [t()]} | {:error, [String.t()]}
  def load_file(path) do
    with {:ok, body} <- File.read(path),
         {:ok, decoded} <- Jason.decode(body),
         {:ok, maps} <- normalize_document(decoded, path) do
      build_cases(maps, path)
    else
      {:error, %Jason.DecodeError{} = error} ->
        {:error, ["#{path}: invalid JSON: #{Exception.message(error)}"]}

      {:error, reason} when is_atom(reason) ->
        {:error, ["#{path}: #{reason}"]}

      {:error, errors} when is_list(errors) ->
        {:error, errors}
    end
  end

  @spec from_map(map()) :: {:ok, t()} | {:error, [String.t()]}
  def from_map(map) when is_map(map) do
    errors =
      []
      |> validate_required_fields(map)
      |> validate_string_fields(map)
      |> validate_string_list_fields(map)
      |> validate_expected_sources(map)
      |> validate_retrieval_k(map)
      |> validate_required_recall(map)

    case errors do
      [] ->
        {:ok,
         %__MODULE__{
           id: Map.fetch!(map, "id"),
           question: Map.fetch!(map, "question"),
           expected_topics: Map.fetch!(map, "expected_topics"),
           must_not_include: Map.fetch!(map, "must_not_include"),
           source_requirements: Map.fetch!(map, "source_requirements"),
           expected_sources: Map.fetch!(map, "expected_sources"),
           retrieval_k: Map.fetch!(map, "retrieval_k"),
           required_recall: Map.fetch!(map, "required_recall") * 1.0
         }}

      errors ->
        {:error, Enum.reverse(errors)}
    end
  end

  def from_map(_other), do: {:error, ["case must be a JSON object"]}

  @spec required_fields() :: [String.t()]
  def required_fields, do: @required_fields

  defp load_files([]), do: {:ok, []}

  defp load_files(paths) do
    paths
    |> Enum.reduce({[], []}, fn path, {cases, errors} ->
      case load_file(path) do
        {:ok, loaded_cases} -> {cases ++ loaded_cases, errors}
        {:error, file_errors} -> {cases, errors ++ file_errors}
      end
    end)
    |> case do
      {cases, []} -> {:ok, cases}
      {_cases, errors} -> {:error, errors}
    end
  end

  defp normalize_document(document, _path) when is_list(document), do: {:ok, document}
  defp normalize_document(document, _path) when is_map(document), do: {:ok, [document]}

  defp normalize_document(_document, path),
    do: {:error, ["#{path}: expected a JSON object or array"]}

  defp build_cases(maps, path) do
    maps
    |> Enum.with_index(1)
    |> Enum.reduce({[], []}, &collect_case(&1, &2, path))
    |> format_case_results()
  end

  defp collect_case({map, index}, {cases, errors}, path) do
    case from_map(map) do
      {:ok, eval_case} -> {[eval_case | cases], errors}
      {:error, case_errors} -> {cases, index_errors(case_errors, path, index) ++ errors}
    end
  end

  defp index_errors(errors, path, index) do
    Enum.map(errors, &"#{path}:#{index}: #{&1}")
  end

  defp format_case_results({cases, []}), do: {:ok, Enum.reverse(cases)}
  defp format_case_results({_cases, errors}), do: {:error, Enum.reverse(errors)}

  defp validate_required_fields(errors, map) do
    missing =
      @required_fields
      |> Enum.reject(&Map.has_key?(map, &1))
      |> Enum.map(&"missing required field #{inspect(&1)}")

    missing ++ errors
  end

  defp validate_string_fields(errors, map) do
    field_errors =
      @required_string_fields
      |> Enum.filter(&Map.has_key?(map, &1))
      |> Enum.reject(&(is_binary(Map.fetch!(map, &1)) and String.trim(Map.fetch!(map, &1)) != ""))
      |> Enum.map(&"#{inspect(&1)} must be a non-empty string")

    field_errors ++ errors
  end

  defp validate_string_list_fields(errors, map) do
    field_errors =
      @required_string_list_fields
      |> Enum.filter(&Map.has_key?(map, &1))
      |> Enum.reject(&string_list?(Map.fetch!(map, &1)))
      |> Enum.map(&"#{inspect(&1)} must be a list of non-empty strings")

    field_errors ++ errors
  end

  defp validate_expected_sources(errors, map) do
    if Map.has_key?(map, "expected_sources") and Map.fetch!(map, "expected_sources") == [] do
      ["\"expected_sources\" must include at least one source" | errors]
    else
      errors
    end
  end

  defp validate_retrieval_k(errors, map) do
    if Map.has_key?(map, "retrieval_k") and not positive_integer?(Map.fetch!(map, "retrieval_k")) do
      ["\"retrieval_k\" must be a positive integer" | errors]
    else
      errors
    end
  end

  defp validate_required_recall(errors, map) do
    if Map.has_key?(map, "required_recall") and not recall?(Map.fetch!(map, "required_recall")) do
      ["\"required_recall\" must be a number between 0.0 and 1.0" | errors]
    else
      errors
    end
  end

  defp string_list?(values) when is_list(values) do
    Enum.all?(values, &(is_binary(&1) and String.trim(&1) != ""))
  end

  defp string_list?(_values), do: false

  defp positive_integer?(value), do: is_integer(value) and value > 0

  defp recall?(value) when is_integer(value), do: value >= 0 and value <= 1
  defp recall?(value) when is_float(value), do: value >= 0.0 and value <= 1.0
  defp recall?(_value), do: false
end
