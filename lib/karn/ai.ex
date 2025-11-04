defmodule Karn.AI do
  @server Karn.Server
  alias Karn.AI.Models

  def start() do
    start([])
  end

  @doc """
  Starts the AI server.

  ## Parameters
  * `opts`: A keyword list of options to pass to the server. See `Karn.AI.Server.start_link/1` for more information.

  ## Returns
  * `{:ok, pid}` if the server was started successfully.
  * `{:error, reason}` otherwise.
  """

  def start(opts) when is_list(opts) do
    case Keyword.get(opts, :model, :default) do
      :default ->
        Karn.Server.start_link(Keyword.put(opts, :name, @server))

      model ->
        case Models.valid(model) do
          :ok -> Karn.Server.start_link(Keyword.put(opts, :name, @server))
          {:error, m} -> Karn.Output.send_error(m)
        end
    end
  end

  @doc """
  Switches the model used by the AI server.

  ## Parameters
  * `model`: The name of the model to switch to.

  ## Returns
  * `:ok` if the model was switched successfully.
  * `{:error, :not_found}` if the model is not available.
  """

  def switch_model(model) do
    case Models.valid(model) do
      :ok -> GenServer.call(@server, {:switch_model, model})
      {:error, m} -> Karn.Output.send_error(m)
    end
  end

  @doc """
  Resets the model to the default.

  ## Returns
  * `:ok` if the model was switched successfully.
  """

  def reset_model() do
    GenServer.call(@server, {:switch_model, Models.default()})
  end

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
    GenServer.call(@server, {:query, cmd})
  end

  @doc """
  Requests AI to explain any specific module.

  ## Parameters
  * `mod`: The module to explain
  * `refs (optional)`: The list of modules which are related to `mod` defaults to `[]`
  * `q (optional)`: The specific question you have about the module/ functions, else a breif explaination is given
  The user can ask follow up questions using `q/1`
  NOTE: Currently the modules are not cached (on client or server)
  NOTE: Feeding too many modules might bloat the context, you can reduce context by firing `reset_context`

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """

  def e(mod), do: e(mod, [], nil)

  def e(mod, q) when is_bitstring(q), do: e(mod, [], q)

  def e(mod, refs) when is_list(refs), do: e(mod, refs, nil)

  def e(mod, ref) when is_atom(ref), do: e(mod, [ref], nil)

  def e(mod, refs, q) do
    GenServer.call(@server, {:explain, mod, refs, q})
  end

  @doc """
  Shows usage per model basis

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """

  def usage() do
    GenServer.call(@server, :usage)
  end

  @doc """
  Terminates the server,prints usage before end

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  """

  def stop() do
    usage()
    GenServer.stop(@server, :normal)
  end

  @doc """
  View context

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """

  def view_context() do
    GenServer.call(@server, :view_context)
  end

  @doc """
  View state of the server

  ## Returns
  The response from the AI server (content and format depend on the server implementation).
  Current (and default implementation) is IO as this is ment to be used through IEX
  * `:done`
  """
  def view_state() do
    GenServer.call(@server, :view_state)
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
  def reset_context(sys \\ nil) do
    GenServer.call(@server, {:reset_context, sys})
  end
end
