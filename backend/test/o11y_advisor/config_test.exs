defmodule O11yAdvisor.ConfigTest do
  use ExUnit.Case, async: false

  @model "google:gemini-3.5-flash"

  test "dev LLM defaults use Gemini Flash" do
    config = read_config(:dev)

    assert config[:arcana][:llm] == @model
    assert config[:tribunal][:llm] == @model
  end

  test "test LLM defaults use Gemini Flash" do
    config = read_config(:test)

    assert config[:arcana][:llm] == @model
    assert config[:tribunal][:llm] == @model
  end

  test "runtime model overrides keep answer and judge models independent" do
    original_llm_model = System.get_env("O11Y_ADVISOR_LLM_MODEL")
    original_judge_model = System.get_env("O11Y_ADVISOR_JUDGE_LLM_MODEL")

    on_exit(fn ->
      restore_env("O11Y_ADVISOR_LLM_MODEL", original_llm_model)
      restore_env("O11Y_ADVISOR_JUDGE_LLM_MODEL", original_judge_model)
    end)

    System.put_env("O11Y_ADVISOR_LLM_MODEL", "openai:gpt-4o-mini")
    System.put_env("O11Y_ADVISOR_JUDGE_LLM_MODEL", "anthropic:claude-3-5-haiku-latest")

    config = Config.Reader.read!(runtime_config_path(), env: :dev)

    assert config[:arcana][:llm] == "openai:gpt-4o-mini"
    assert config[:tribunal][:llm] == "anthropic:claude-3-5-haiku-latest"
  end

  defp read_config(env) do
    Config.Reader.read!(config_path(), env: env)
  end

  defp config_path do
    Path.expand("../../config/config.exs", __DIR__)
  end

  defp runtime_config_path do
    Path.expand("../../config/runtime.exs", __DIR__)
  end

  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end
