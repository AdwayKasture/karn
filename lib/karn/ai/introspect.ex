defmodule Karn.AI.Introspect do
  @moduledoc false

  # TODO: Decide how to handle introspection for kernel using Code.fetch_docs()
  # Or integration with tide wave

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
