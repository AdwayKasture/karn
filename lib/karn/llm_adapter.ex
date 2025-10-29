defmodule Karn.LLMAdapter do

  @moduledoc """
  This is a wrapper around ReqLLM, its only added for testing, 
  Once and idoimatic way of testing for reqllm is established use that 
  """

 @callback generate_text(model :: atom(), context_list :: list()) ::
              {:ok, map()} | {:error, map()} 


  def generate_text(model,ctx), do: impl().generate_text(model,ctx) 

  defp impl() do
    Application.get_env(:karn,:llm_adapter,ReqLLM)
  end
  
end
