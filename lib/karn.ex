defmodule Karn do
  @moduledoc """
  A client interface for interacting with the main AI service, managed by
  `Karn.Server`.

  This module provides convenient functions for querying the AI, explaining code
  or modules,
  viewing/managing the conversation context,viewing usage and stopping the service.

  ### Usage Example

      # Query the AI
      Karn.q("What is the difference between Elixir and Erlang?")

      # Explain a module with specific references
      Karn.e(MyModule, [MyModule.A, DependentModule], "How does function xyz work?")

      # View the current conversation context
      Karn.view_context()

      # Reset the conversation context
      Karn.reset_context()

      # View usage()
      Karn.usage()

      # switch model
      Karn.switch_model("google:gemini-2.0")

      # reset model
      Karn.reset_model
  """

  alias Karn.AI

  @doc """
  Starts the AI server.

  ## Parameters
  * `opts`: A keyword list of options to pass to the server. See `Karn.AI.Server.start_link/1` for more information.

  ## Returns
  * `{:ok, pid}` if the server was started successfully.
  * `{:error, reason}` otherwise.
  """
  defdelegate start(), to: AI
  defdelegate start(opts), to: AI

  @doc """
  Switches the model used by the AI server.

  ## Parameters
  * `model`: The name of the model to switch to.

  ## Returns
  * `:ok` if the model was switched successfully.
  * `{:error, :not_found}` if the model is not available.
  """
  defdelegate switch_model(model), to: AI

  @doc """
  Resets the model to the default.

  ## Returns
  * `:ok` if the model was switched successfully.
  """
  defdelegate reset_model(), to: AI

  @doc """
  Sends a natural language query (`cmd`) to the AI server.

  This is the primary function for asking the AI questions or giving it instructions.
  You can ask follow up questions on previous queries and explainations.

  ## Parameters
  * `cmd`: The string command or query to send to the AI.

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """
  defdelegate q(cmd), to: AI

  @doc """
  Requests AI to explain any specific module.

  ## Parameters
  * `mod`: The module to explain
  * `refs`: The list of modules which are related to `mod` defaults to `[]`
  * `q`: The specific question you have about the module/ functions, else a breif explaination is given
  The user can ask follow up questions using `q/1`
  NOTE: Currently the modules are not cached (on client or server)
  NOTE: Feeding too many modules might bloat the context, you can reduce context by firing `reset_context`

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """
  defdelegate e(mod), to: AI
  defdelegate e(mod, q_or_refs), to: AI
  defdelegate e(mod, refs, q), to: AI

  @doc """
  Shows usage per model basis

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """
  defdelegate usage(), to: AI

  @doc """
  Terminates the server,prints usage before end

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  """
  defdelegate stop(), to: AI

  @doc """
  View context

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """
  defdelegate view_context(), to: AI

  @doc """
  View state of the server

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """
  defdelegate view_state(), to: AI

  @doc """
  Reset context

  ## Parameters
  * `sys`: Optional system prompt, if non is resorts to default

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """
  defdelegate reset_context(sys \\ nil), to: AI
end
