defmodule Karn.AI.Prompts do
  @doc false

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

  def explain_module(code, mods, q) do
    part =
      if q,
        do: "Understand the above code and explain #{q}",
        else: "Understand the above code and explain it."

    """
    #{code}
    #{part}
    If its a very large module share some key functions you can use 
    If you need any more information or have questions you can ask the user.
    You can also request user for specific modules.
    Some other relevant modules are
    #{mods}
    """
  end
end
