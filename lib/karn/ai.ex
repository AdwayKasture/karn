defmodule Karn.Ai do

  @server Karn.Ai.Server
  @moduledoc """
  A client interface for interacting with the main AI service, managed by
  `Karn.Ai.Server`.

  This module provides convenient functions for querying the AI, explaining code
  or modules,
  viewing/managing the conversation context,viewing usage and stopping the service.

  ### Usage Example

      # Query the AI
      Karn.Ai.q("What is the difference between Elixir and Erlang?")

      # Explain a module with specific references
      Karn.Ai.e(MyModule, [MyModule.A, DependentModule], "How does function xyz work?")

      # View the current conversation context
      Karn.Ai.view_context()

      # Reset the conversation context
      Karn.Ai.reset_context()

      # View usage()
      Karn.Ai.usage()

      # switch model
      Karn.Ai.switch("google:gemini-2.0")
  """
 
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
  def q(cmd) do
    GenServer.call(@server,{:query,cmd})
  end


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

  def e(mod),do: e(mod,[],nil)

  def e(mod,q) when is_bitstring(q),do: e(mod,[],q)

  def e(mod,refs) when is_list(refs),do: e(mod,refs,nil)
 
  def e(mod,refs,q) do
    GenServer.call(@server,{:explain,mod,refs,q})
  end

  @doc """
  Shows usage per model basis

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """
 
  def usage() do
    GenServer.call(@server,:usage)
  end

  @doc """
  Terminates the server,prints usage before end

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  """
 
  def stop() do
    usage()
    GenServer.stop(@server,"User ended session")
  end

  @doc """
  View context

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """
 
  def view_context() do
    GenServer.call(@server,:view_context)
  end


  @doc """
  Reset context

  ## Parameters
  * `sys`: Optional system prompt, if non is resorts to default

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """
 
  def reset_context(sys\\nil) do
    GenServer.call(@server,{:reset_context,sys})
  end

 
end
