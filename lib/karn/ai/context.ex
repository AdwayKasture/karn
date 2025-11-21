defmodule Karn.AI.Context do
  alias Karn.AI.Prompts
  alias ReqLLM.Context

  def new() do
    Context.new([Context.system(Prompts.base(), %{message_id: 0})])
  end

  def new(message) do
    Context.new([Context.system(message, %{message_id: 0})])
  end
end
