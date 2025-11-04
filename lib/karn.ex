defmodule Karn do
  @moduledoc """
  A client interface for interacting with the main AI service

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

  @doc delegate_to: {AI,:start,1}
  defdelegate start(), to: AI

  @doc delegate_to: {AI,:start,1}
  defdelegate start(opts), to: AI

  @doc delegate_to: {AI,:switch_model,1}
  defdelegate switch_model(model), to: AI

  @doc delegate_to: {AI,:reset_model,1}
  defdelegate reset_model(), to: AI


  @doc delegate_to: {AI,:q,1}
  defdelegate q(cmd), to: AI



  @doc delegate_to: {AI,:e,1}
  defdelegate e(mod), to: AI
  defdelegate e(mod, q_or_refs), to: AI
  defdelegate e(mod, refs, q), to: AI


  @doc delegate_to: {AI,:usage,1}
  defdelegate usage(), to: AI


  @doc delegate_to: {AI,:stop,0}
  defdelegate stop(), to: AI


  @doc delegate_to: {AI,:view_context,0}
  defdelegate view_context(), to: AI

  @doc delegate_to: {AI,:view_state,0}
  defdelegate view_state(), to: AI


  @doc delegate_to: {AI,:reset_context,1}
  defdelegate reset_context(sys \\ nil), to: AI
end
