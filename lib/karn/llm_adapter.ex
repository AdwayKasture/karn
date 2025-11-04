defmodule Karn.LLMAdapter do
  @moduledoc false

  @callback generate_text(model :: atom(), context_list :: list()) ::
              {:ok, map()} | {:error, map()}

  def generate_text(model, ctx) do
    try do
      impl().generate_text(model, ctx)
    rescue
      e in ReqLLM.Error.Invalid.Parameter -> {:error, "Invalid parameter: #{e.parameter}"}
    end
  end

  defp impl() do
    Application.get_env(:karn, :llm_adapter, ReqLLM)
  end
end
