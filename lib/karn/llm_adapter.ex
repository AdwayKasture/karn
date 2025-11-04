defmodule Karn.LLMAdapter do
  @moduledoc false

  @callback generate_text(model :: atom(), context_list :: list()) ::
              {:ok, map()} | {:error, map()}

  def generate_text(model, ctx), do: impl().generate_text(model, ctx)

  defp impl() do
    Application.get_env(:karn, :llm_adapter, ReqLLM)
  end
end
