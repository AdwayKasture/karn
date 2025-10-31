defmodule Mix.Tasks.Karn.Install.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Quickly install your dev chatbot"
  end

  @spec example() :: String.t()
  def example do
    "mix karn.install --google"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    ## Example

    ```sh
    #{example()}
    ```

    ## Options

    * `--claude`
    * `--google`
    * `--xai`
    * `--openai`
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Karn.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :karn,
        # *other* dependencies to add
        # i.e `{:foo, "~> 2.0"}`
        adds_deps: [],
        # *other* dependencies to add and call their associated installers, if they exist
        # i.e `{:foo, "~> 2.0"}`
        installs: [],
        # An example invocation
        example: __MODULE__.Docs.example(),
        # A list of environments that this should be installed in.
        only: nil,
        # a list of positional arguments, i.e `[:file]`
        positional: [],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: [],
        # `OptionParser` schema
        schema: [],
        # Default values for the options in the `schema`
        defaults: [],
        # CLI aliases
        aliases: [],
        # A list of options in the schema that are required
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      app_name = Igniter.Project.Application.app_name(igniter)
      opts = igniter.args.options

      model =
        cond do
          # Keyword.has_key?(opts,:google) -> "google:gemini-2.0-flash" 
          Keyword.has_key?(opts, :anthropic) -> "anthropic"
          Keyword.has_key?(opts, :openai) -> "openai:model"
          Keyword.has_key?(opts, :xai) -> "grok:model"
          true -> "google:gemini-2.0-flash"
        end

      # Do your work here and return an updated igniter
      igniter
      |> Igniter.Project.Config.configure_new("dev.exs", app_name, [Karn],
        default_model: model,
        output: Karn.Output.IO
      )
      |> Igniter.add_notice(
        "Installation done !!!,add your api keys to the environment and you are good to go !!"
      )
    end
  end
else
  defmodule Mix.Tasks.Karn.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'karn.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
