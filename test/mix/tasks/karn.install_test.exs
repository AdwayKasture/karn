defmodule Mix.Tasks.Karn.InstallTest do
  use ExUnit.Case, async: true
  import Igniter.Test
  @moduletag :tasks

  @model_switches [
    {"--google", "google:gemini-2.0-flash"},
    {"--openai", "openai:model"},
    {"--anthropic", "anthropic"},
    {"--xai", "grok:model"}
  ]

  @moduledoc """
  Keyword.get(parsed_opts,:google) -> "google:gemini-2.0-flash" 
        Keyword.get(parsed_opts,:anthropic) -> "anthropic"
        Keyword.get(parsed_opts,:openai) -> "openai:model"
        Keyword.get(parsed_opts,:xai) -> "grok:model"

  """

  test "sanity check" do
    # generate a test project
    test_project()
    # run our task
    |> Igniter.compose_task("karn.install", [])
    # see tools in `Igniter.Test` for available assertions & helpers
    |> assert_has_notice(
      "Installation done !!!,add your api keys to the environment and you are good to go !!"
    )
  end

  test "default model selection" do
    [app_name: :karn]
    |> test_project()
    |> Igniter.compose_task("karn.install", [])
    |> assert_has_patch(
      "config/dev.exs",
      """
      |config :karn, Karn, default_model: "google:gemini-2.0-flash", output: Karn.Output.IO
      |
      """
    )
  end

  @tag :aa
  test "custom model selection" do
    for {flag, model} <- @model_switches do
      [app_name: :karn]
      |> test_project()
      |> Igniter.compose_task("karn.install", ["arg", flag])
      |> assert_has_patch(
        "config/dev.exs",
        """
        |config :karn, Karn, default_model: "#{model}", output: Karn.Output.IO
        |
        """
      )
    end
  end
end
