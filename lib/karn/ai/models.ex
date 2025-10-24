defmodule Karn.Ai.Models do
  @moduledoc """
  TODO 
  Provide list of standard/recommended models
  Available models.
  """

  @default "google:gemini-2.0-flash"

  @spec default :: String.t()
  def default, do: @default

  def valid?(model) do
    is_binary(model) and String.contains?(model, ":") and String.length(model) > 2
  end
end
