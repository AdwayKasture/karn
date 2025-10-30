defmodule Karn.AI.Models do
  @moduledoc """
  """
  alias ReqLLM.Provider.Registry

  @default "google:gemini-2.0-flash"

  @spec default :: String.t()
  def default, do: @default

  @spec valid(String.t()) :: :ok | {:error, String.t()}
  def valid(model) do
    if Registry.model_exists?(model) do
      :ok
    else
      generate_error(model)
    end
  end

  @spec generate_error(String.t()) :: {:error, String.t()}
  defp generate_error(model) do
    with [provider, m] <- String.split(model, ":"),
         {:ok, prov_id} <- get_provider(provider) do
      {:ok, listed_models} = Registry.list_models(prov_id)

      models =
        listed_models
        |> Enum.map(fn m -> to_string(m) end)
        |> Enum.reduce("", fn l, r -> l <> "\n" <> r end)

      {:error, "Only #{models} are supported. You provided: #{m}"}
    else
      [_m] -> {:error, "model must be in format provider:model like #{"google:gemini-2.0-flash"}"}
      {:error, m} -> {:error, m}
    end
  end

  @spec get_provider(String.t()) :: {:error, String.t()} | {:ok, atom()}
  defp get_provider(provider) do
    try do
      prov_id = String.to_existing_atom(provider)

      if prov_id in Registry.list_providers() do
        {:ok, prov_id}
      else
        {:error, "#{provider} is not a recognised provider."}
      end
    rescue
      _ -> {:error, "No such provider exists"}
    end
  end
end
