defmodule Mix.Tasks.Karn.InstallTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  @model_switches [
    {"--google", "google:gemini-2.0-flash"},
    {"--openai", "openai:gpt-4o-mini"},
    {"--anthropic", "anthropic:claude-3-5-haiku-20241022"}
  ]

  test "sanity check" do
    # generate a test project
    test_project()
    # run our task
    |> Igniter.compose_task("karn.install", [])
    # see tools in `Igniter.Test` for available assertions & helpers
    |> assert_has_notice("""
    Installation done !!!
    configure your enviornment as mentioned on
    https://hexdocs.pm/req_llm/ReqLLM.Providers.Google.html
    """)
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

  test "correct docs picked up" do
    [app_name: :karn]
    |> test_project()
    |> Igniter.compose_task("karn.install", ["arg", "--anthropic"])
    |> assert_has_patch(
      "config/dev.exs",
      """
      |config :karn, Karn, default_model: "anthropic:claude-3-5-haiku-20241022", output: Karn.Output.IO
      |
      """
    )
    |> assert_has_notice("""
    Installation done !!!
    configure your enviornment as mentioned on
    https://hexdocs.pm/req_llm/ReqLLM.Providers.Anthropic.html
    """)
  end
end
