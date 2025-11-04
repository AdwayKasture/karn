defmodule Karn.AI do
  @server Karn.Server
  alias Karn.AI.Models

  @moduledoc false

  def start() do
    start([])
  end

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

  def switch_model(model) do
    case Models.valid(model) do
      :ok -> GenServer.call(@server, {:switch_model, model})
      {:error, m} -> Karn.Output.send_error(m)
    end
  end

  def reset_model() do
    GenServer.call(@server, {:switch_model, Models.default()})
  end

  def q(cmd) do
    GenServer.call(@server, {:query, cmd})
  end

  def e(mod), do: e(mod, [], nil)

  def e(mod, q) when is_bitstring(q), do: e(mod, [], q)

  def e(mod, refs) when is_list(refs), do: e(mod, refs, nil)

  def e(mod, ref) when is_atom(ref), do: e(mod, [ref], nil)

  def e(mod, refs, q) do
    GenServer.call(@server, {:explain, mod, refs, q})
  end

  def usage() do
    GenServer.call(@server, :usage)
  end

  def stop() do
    usage()
    GenServer.stop(@server, :normal)
  end

  def view_context() do
    GenServer.call(@server, :view_context)
  end

  def view_state() do
    GenServer.call(@server, :view_state)
  end

  def reset_context(sys \\ nil) do
    GenServer.call(@server, {:reset_context, sys})
  end
end
