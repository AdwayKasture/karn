defmodule Karn.Server do
  alias Karn.LLMAdapter
  alias Karn.AI.{Introspect, Prompts, Models}
  alias Karn.State
  alias Karn.Output
  alias ReqLLM.{Response, Context}
  use GenServer

  @moduledoc false

  def start_link(opts) do
    model = Keyword.get(opts, :model, Models.default())

    init = %State{
      context: new(),
      model: model,
      usage: %{
        model => %{
          input_tokens: 0,
          output_tokens: 0,
          cached_tokens: 0,
          reasoning_tokens: 0,
          total_tokens: 0,
          total_cost: 0.0,
          input_cost: 0.0,
          output_cost: 0.0
        }
      }
    }

    GenServer.start_link(__MODULE__, init, opts)
  end

  @impl GenServer
  def init(ctx) do
    send(self(), :start)
    {:ok, ctx}
  end

  @impl GenServer
  def handle_info(:start, state) do
    Output.send_response("Ask your elixir query")
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(
        {:query, cmd},
        _from,
        %State{context: ctx, usage: usg, model: model} = state
      ) do
    req = Context.user(cmd)

    {usage, ctx} =
      case LLMAdapter.generate_text(model, Context.to_list(Context.append(ctx,req))) do
        {:error, resp} ->
          handle_error(resp)
          {usg, ctx}

        {:ok, resp} ->
          update_context(req, resp, state)
      end

    usage = Map.put(usg, model, usage)
    {:reply, :done, %State{model: model, context: ctx, usage: usage}}
  end

  # TODO needs proper refactor
  @impl GenServer
  def handle_call(
        {:explain, mod, refs, q},
        _from,
        state = %State{context: ctx, usage: usg, model: model}
      ) do

    case Introspect.module(mod) do
      {:ok, module_file} ->
        ref_files =
          refs
          |> Enum.map(fn ref -> Introspect.module(ref) end)
          |> Enum.flat_map(fn
            {:ok, d} -> [d]
            {:error, _r} -> []
          end)
          |> Enum.reduce("", fn l, r -> l <> "\n" <> r end)

        req = Context.user(Prompts.explain_module(module_file, ref_files, q))

        {usage, ctx} =
          case LLMAdapter.generate_text(model, Context.to_list(Context.append(ctx,req))) do
            {:error, resp} ->
              handle_error(resp)
              {usg, ctx}

            {:ok, resp} ->
              update_context(req, resp, state)
          end

        usage = Map.put(usg, model, usage)
        {:reply, :done, %State{context: ctx, model: model, usage: usage}}

      {:error, reason} ->
        Output.send_error("Failed to explain module: #{reason}")
        {:reply, :done, state}
    end
  end

  @impl GenServer
  def handle_call(:usage, _from, %State{usage: usg} = ctx) do
    Output.send_usage(usg)
    {:reply, :done, ctx}
  end

  @impl GenServer
  def handle_call(:view_state, _from, ctx) do
    Output.send_state(ctx)
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

    Output.send_blocks(messages)
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
    new_usage =
      Map.put_new(state.usage, model, %{
        input_tokens: 0,
        output_tokens: 0,
        cached_tokens: 0,
        reasoning_tokens: 0,
        total_tokens: 0,
        total_cost: 0.0,
        input_cost: 0.0,
        output_cost: 0.0
      })

    new_state  = state
    |> Map.put(:model, model)
    |> Map.put(:usage, new_usage)

    {:reply, :ok, new_state}
  end

  defp new() do
    Context.new([Context.system(Prompts.base())])
  end

  defp handle_error(resp) do
    case resp do
      %ReqLLM.Error.Validation.Error{reason: r} ->
        Output.send_error(r)

      %ReqLLM.Error.API.Request{reason: reason, status: status} ->
        Output.send_error("Failed to make query due to #{reason}, with status code #{status}")

      unknown ->
        Output.send_error("Failed due to #{unknown}")
    end
  end

  # TODO extract common handling for query and explain
  defp update_context(req, resp, state) when is_struct(state, State) do
    usage = Map.merge(resp.usage, state.usage[state.model], fn _k, l, r -> l + r end)
    text = Response.text(resp)
    ctx = Context.append(state.context, req)
    ctx = Context.append(ctx, Context.assistant(text))
    Output.send_response(text)
    {usage, ctx}
  end
end
