defmodule Karn.Server do
  alias Karn.Usage
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
      usage: %{model => Usage.new()}
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
    Output.send_response(Prompts.start_prompt())
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(
        {:query, cmd},
        _from,
        %State{context: ctx, usage: usg, model: model} = state
      ) do
    req = Context.user(cmd)
    ctx_with_req = Context.append(ctx, req)

    case LLMAdapter.generate_text(model, Context.to_list(ctx_with_req)) do
      {:error, resp} ->
        handle_error(resp)
        {:reply, :done, state}

      {:ok, resp} ->
        usage = Usage.update(usg[model], resp.usage)
        final_ctx = handle_response(resp, ctx_with_req)
        updated_usage = Map.put(usg, model, usage)
        {:reply, :done, %State{state | context: final_ctx, usage: updated_usage}}
    end
  end

  @impl GenServer
  def handle_call(
        {:explain, mod, refs, query},
        _from,
        %State{usage: usg, model: model} = state
      ) do
    all_modules = [mod | refs]

    introspection_results =
      Enum.map(all_modules, fn module -> {module, Introspect.module(module)} end)

    {successful_introspections, failed_introspections} =
      Enum.split_with(introspection_results, fn {_, result} -> elem(result, 0) == :ok end)

    Enum.each(failed_introspections, fn {module, {:error, reason}} ->
      Output.send_error("Failed to introspect module #{module}: #{reason}")
    end)

    if Enum.any?(successful_introspections, fn {module, _} -> module == mod end) do
      file_messages =
        successful_introspections
        |> Enum.map(fn {module, {:ok, content}} ->
          Context.user(content, %{ref: module})
        end)

      valid_refs =
        successful_introspections
        |> Enum.map(fn {module, _} -> module end)
        |> List.delete(mod)

      query_msg =
        query
        |> Prompts.explain_module(mod, valid_refs)
        |> Context.user()

      temp_ctx =
        state.context
        |> upsert_messages(file_messages)
        |> Context.append(query_msg)

      case LLMAdapter.generate_text(model, Context.to_list(temp_ctx)) do
        {:error, resp} ->
          handle_error(resp)
          {:reply, :done, state}

        {:ok, resp} ->
          usage = Usage.update(usg[model], resp.usage)
          final_ctx = handle_response(resp, temp_ctx)
          updated_usage = Map.put(usg, model, usage)
          {:reply, :done, %State{state | context: final_ctx, usage: updated_usage}}
      end
    else
      Output.send_error(
        "Failed to explain module: Primary module #{mod} could not be introspected."
      )

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
  def handle_call(:view_context, _from, %State{context: ctx} = state) do
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
      Map.put_new(state.usage, model, Usage.new())

    new_state =
      state
      |> Map.put(:model, model)
      |> Map.put(:usage, new_usage)

    {:reply, :ok, new_state}
  end

  defp upsert_messages(context, messages_to_upsert) do
    existing_messages = Context.to_list(context)

    final_messages =
      Enum.reduce(messages_to_upsert, existing_messages, fn new_msg, acc_messages ->
        # Use Map.get for safety
        ref_to_find = Map.get(new_msg.metadata, :ref)

        # Use 'with' to bind the index if the ref exists and the index is found.
        with index when is_integer(index) <- find_message_index(acc_messages, ref_to_find) do
          # Success path: Index found (UPDATE)
          List.replace_at(acc_messages, index, new_msg)
        else
          # Failure path: Index is nil, or ref_to_find was nil (INSERT)
          _ -> acc_messages ++ [new_msg]
        end
      end)

    Context.new(final_messages)
  end

  defp find_message_index(_messages, ref_to_find) when is_nil(ref_to_find), do: nil

  defp find_message_index(messages, ref_to_find) do
    Enum.find_index(messages, fn msg ->
      Map.get(msg, :metadata) && Map.get(msg.metadata, :ref) == ref_to_find
    end)
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

  defp handle_response(resp, ctx) do
    text = Response.text(resp)
    Output.send_response(text)
    Context.append(ctx, Context.assistant(text))
  end
end
