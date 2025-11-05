defmodule Karn.AI.Prompts do
  @moduledoc false

  def base() do
    """
    You are an Senior Elixir developer, 
    You must respond in 5 lines or less whenever possible,
    No need to do md format just text, 
    This is supposed to be used in iex repl,
    If only code is asked only respond with code.
    Don't speculate if you need more information from user always ask.
    """
  end

  def explain_module(q, mod, refs \\ []) do
    part =
      if q !== nil,
        do: "Understand the #{mod} code and explain #{q}",
        else: "Understand the #{mod} code and explain it."

    ref_part =
      if refs != [],
        do: "Keep in mind the following modules while answering: #{Enum.join(refs, ", ")}",
        else: ""

    """
    #{part}
    #{ref_part}
    If its a very large module share some key functions  and their working
    If you need any more information or have questions you can ask the user.
    You can also request user for specific modules.
    """
  end

  def start_prompt() do
    """
    1. Select your model with switch_model "provider:model"
    2. Configure your API key, refer to https://hexdocs.pm/req_llm/overview.html#api-key-management
    3. You can ask questions like q "What is a dynamic supervisor ?"
    4. You can ask questions related to source code like e Karn,[Karn.Server], "Give me detailed explanatation of how Karn works !!"
    5. Have fun !!!
    """
  end
end
