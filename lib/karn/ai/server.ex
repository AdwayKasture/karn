defmodule Karn.Ai.Server do
  alias Karn.Ai.{Introspect, Prompts, State, Models}
  alias Karn.Output
  alias ReqLLM.{Response, Context}
  use GenServer

  @moduledoc false

  def start_link(opts) do
    model = Keyword.get(opts, :model, Models.default())

    init = %State{
      context: new(),
      turn: :user,
      model: model,
      usage: %{model => %{input_tokens: 0, output_tokens: 0, total_cost: 0.0}}
    }

    GenServer.start_link(__MODULE__, init, opts)
  end

  @impl GenServer
  def init(ctx) do
    send(self(), :start)
    {:ok, ctx}
  end

  @impl GenServer
  def handle_info(:start, ctx) do
    Output.IO.send_response("Ask your elixir query")
    {:noreply, ctx}
  end

  @impl GenServer
  def handle_call(
        {:query, cmd},
        _from,
        %State{turn: :user, context: ctx, usage: usg, model: model} = state
      ) do
    ctx = Context.append(ctx, Context.user(cmd))

    {usage, ctx} =
      case ReqLLM.generate_text(model, Context.to_list(ctx)) do
        {:error, resp} ->
          handle_error(resp)
          {usg, ctx}

        {:ok, resp} ->
          update_context(resp, state)
      end

    usage = Map.put(usg, model, usage)
    {:reply, :done, %State{turn: :user, model: model, context: ctx, usage: usage}}
  end

  # TODO make modules as separate messages so it can be cached
  @impl GenServer
  def handle_call(
        {:explain, mod, refs, q},
        _from,
        state = %State{turn: :user, context: ctx, usage: usg, model: model}
      ) do
    {:ok, module_file} = Introspect.module(mod)

    ref_files =
      refs
      |> Enum.map(fn ref -> Introspect.module(ref) end)
      |> Enum.flat_map(fn
        {:ok, d} -> [d]
        {:error, _r} -> []
      end)
      |> Enum.reduce("", fn l, r -> l <> "\n" <> r end)

    ctx = Context.append(ctx, Context.user(Prompts.explain_module(module_file, ref_files, q)))

    {usage, ctx} =
      case ReqLLM.generate_text(model, Context.to_list(ctx)) do
        {:error, resp} ->
          handle_error(resp)
          {usg, ctx}

        {:ok, resp} ->
          update_context(resp, state)
      end

    usage = Map.put(usg, model, usage)
    {:reply, :done, %State{turn: :user, context: ctx, model: model, usage: usage}}
  end

  @impl GenServer
  def handle_call(:usage, _from, %State{usage: usg} = ctx) do
    Output.IO.send_usage(usg)
    {:reply, :done, ctx}
  end

  @impl GenServer
  def handle_call(:view_context, _from, state = %State{context: ctx}) do
    messages =
      Context.to_list(ctx)
      |> Enum.map(fn m ->
        [content] = m.content
        %{role: m.role, text: content.text}
      end)

    Output.IO.send_blocks(messages)
    {:reply, :done, state}
  end

  # TODO might want to update usage per session and total basis
  @impl GenServer
  def handle_call({:reset_context, query}, _from, state) do
    q =
      case query do
        nil -> Prompts.base()
        v -> v
      end

    ctx = Context.new([Context.system(q)])
    state = Map.put(state, :context, ctx)

    {:reply, :done, state}
  end

  @impl GenServer
  def handle_call({:switch_model, model}, _from, state) do
    state = Map.put(state, :model, model)
    {:reply, :ok, state}
  end

  defp new() do
    Context.new([Context.system(Prompts.base())])
  end

  defp handle_error(resp) do
    case resp do
      %ReqLLM.Error.Validation.Error{reason: r} ->
        Output.IO.send_error(r)

      %ReqLLM.Error.API.Request{reason: reason, status: status} ->
        Output.IO.send_error("Failed to make query due to #{reason}, with status code #{status}")

      unknown ->
        Output.IO.send_error("Failed due to #{unknown}")
    end
  end

  defp update_context(resp, state) when is_struct(state, State) do
    usage = Map.merge(resp.usage, state.usage[state.model], fn _k, l, r -> l + r end)
    text = Response.text(resp)
    ctx = Context.append(state.context, Context.assistant(text))
    Output.IO.send_response(text)
    {usage, ctx}
  end
end
