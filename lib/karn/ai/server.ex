defmodule Karn.Ai.Server do
  alias Karn.Ai.{Introspect,Prompts,State}
  alias Karn.Output
  alias ReqLLM.{Response,Context}
  use GenServer

  @moduledoc false

  @model "google:gemini-2.0-flash"

  def start_link(opts\\[name: __MODULE__]) do
    init = %State{context: new(),
      turn: :user,
      model: @model,
      usage: %{@model => %{input_tokens: 0,output_tokens: 0,total_cost: 0.0}}}
    GenServer.start_link(__MODULE__,init,opts)
  end

  @impl GenServer
  def init(ctx) do
    send(self(),:start)
    {:ok,ctx}
  end

  @impl GenServer
  def handle_info(:start, ctx) do
    Output.IO.send_response("Ask your elixir query")
    {:noreply,ctx}
  end

  @impl GenServer
  def handle_call({:query,cmd},_from,%State{turn: :user,context: ctx,usage: usg}) do
    
    ctx = Context.append(ctx,Context.user(cmd))

    {:ok,resp} = ReqLLM.generate_text(@model,Context.to_list(ctx))
    usage = Map.merge(resp.usage,usg[@model],fn _k,l,r ->  l+r end)
    text = Response.text(resp)
    ctx = Context.append(ctx,Context.assistant(text))
    Output.IO.send_response(text)
    {:reply,:done,%State{turn: :user,context: ctx,usage: %{usg|@model => usage}}}
  end

  @impl GenServer
  def handle_call({:explain,mod,refs,q},_from,%State{turn: :user,context: ctx,usage: usg}) do
      {:ok,module_file} = Introspect.module(mod)
      ref_files = refs 
      |> Enum.map(fn ref -> Introspect.module(ref) end)
      |> Enum.flat_map(fn 
        {:ok,d} -> [d]
        {:error,_r} -> []
      end)
      |> Enum.reduce("",fn l,r -> l <>"\n"<>r end)

    ctx = Context.append(ctx,Context.user(Prompts.explain_module(module_file,ref_files,q)))
    {:ok,resp} = ReqLLM.generate_text(@model,Context.to_list(ctx))
    usage = Map.merge(resp.usage,usg[@model],fn _k,l,r ->  l+r end)
    text = Response.text(resp)
    ctx = Context.append(ctx,Context.assistant(text))
    Output.IO.send_response(text)
    {:reply,:done,%State{turn: :user,context: ctx,usage: %{usg|@model => usage}}}
  end

  @impl GenServer
  def handle_call({:function,mod,refs,q},_from,%State{turn: :user,context: ctx,usage: usg}) do
      {:ok,module_file} = Introspect.module(mod)
      ref_files = refs 
      |> Enum.map(fn ref -> Introspect.module(ref) end)
      |> Enum.flat_map(fn 
        {:ok,d} -> [d]
        {:error,_r} -> []
      end)
      |> Enum.reduce("",fn l,r -> l <>"\n"<>r end)

    ctx = Context.append(ctx,Context.user(Prompts.explain_module(module_file,ref_files,q)))
    {:ok,resp} = ReqLLM.generate_text(@model,Context.to_list(ctx))
    usage = Map.merge(resp.usage,usg[@model],fn _k,l,r ->  l+r end)
    text = Response.text(resp)
    ctx = Context.append(ctx,Context.assistant(text))
    Output.IO.send_response(text)
    {:reply,:done,%State{turn: :user,context: ctx,usage: %{usg|@model => usage}}}
  end

  @impl GenServer
  def handle_call(:usage,_from,%State{usage: usg}=ctx) do
    Output.IO.send_usage(usg)
    {:reply,:done,ctx}
  end


  @impl GenServer
  def handle_call(:view_context,_from,state = %State{context: ctx}) do
    messages = Context.to_list(ctx)
    |> Enum.map(fn m -> 
      [content] = m.content
     %{role: m.role,text: content.text} end)


    Output.IO.send_blocks(messages)
    {:reply,:done,state}
  end

  # TODO might want to update usage per session and total basis
  @impl GenServer
  def handle_call({:reset_context,query},_from,state) do
    q = case query do
      nil -> Prompts.base()
      v -> v
    end

    ctx = Context.new([Context.system(q)])
    state = Map.put(state,:context,ctx)

    {:reply,:done,state}
  end

 

  defp new() do
    Context.new([Context.system(Prompts.base())])
  end

  def start() do 
    start_link()
  end
  
end
