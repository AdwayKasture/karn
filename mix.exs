defmodule Karn.MixProject do
  use Mix.Project

  @version "0.1.0"

  @source_url "https://github.com/AdwayKasture/karn"

  def project do
    [
      app: :karn,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [
        ignore_modules: [Karn.AI.Prompts, Karn.Test.Fixtures, Mix.Tasks.Karn.Install.Docs]
      ],
      
      #Hex 
      description: description(),
      package: package(),


      #Docs
      name: "Karn",
      docs: [
        main: "overview",
        extras: [{"README.md", title: "Overview", filename: "overview"}]
      ]
    ]
  end

  defp description do
    "Karn is an interactive AI assistant for your Elixir codebase, designed to be used within an IEx session."
  end

  defp package do
    [
      maintainers: ["Adway Kasture"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:req_llm, "~> 1.0.0-rc.4"},
      {:mox, "~> 1.2", only: [:test]},
      {:igniter, "~> 0.6", optional: true}

    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end
