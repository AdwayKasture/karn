defmodule Karn.AI.Introspect do
  @moduledoc """
  Provides functions for introspection of Elixir modules, primarily focusing on
  attempting to retrieve the source file content for a given module.

  The main purpose is to give context to the LLM about the module.
  Current strategy is to check if the module has a source file (from deps or proj)
  and use its file.
  If its part of std lib we expect LLM to know it before hand 
  """

  # TODO: Decide how to handle introspection for kernel using Code.fetch_docs()
  # Or integration with tide wave

  @doc """
  Attempts to retrieve the source file content for a given module.

  ## Examples

      iex> Karn.Ai.Introspect.module(Karn.Ai.Introspect)
      {:ok, "defmodule Karn.Ai.Introspect do\n\n  # TODO decide how to handle\n  # introspection for kernel using Code.fetch_docs()\n  # Or integration with tide wave\n  def module(m) do\n  ...\n"}

      iex> Karn.Ai.Introspect.module(Enum)
      {:ok, "Enum from std lib of elixir"}

      iex> Karn.Ai.Introspect.module(NonExistentModule)
      {:error, "Invalid module provided"}

      iex> Karn.Ai.Introspect.module(:atom_not_a_module)
      # May return an error tuple related to beam_lib depending on the atom/path
      # or {:error, "Invalid module provided"}
  """
  @spec module(module) :: {:ok, String.t()} | {:error, String.t()}
  def module(m) do
    with l when is_list(l) <- :code.which(m),
         {:ok, {_, i}} <- :beam_lib.chunks(l, [:compile_info]) do
      i
      |> Keyword.get(:compile_info)
      |> Keyword.get(:source)
      |> List.to_string()
      |> File.read()
      |> case do
        {:error, :enoent} -> {:ok, "#{m} from std lib of elixir"}
        v -> v
      end
    else
      :non_existing ->
        {:error, "Invalid module provided"}
        # {:error, :beam_lib, reason} -> {:error, "#{m}: failed to read chunks;\n #{reason}"}
    end
  end

  def module?(a) do
    Code.ensure_loaded?(a)
  end
end
