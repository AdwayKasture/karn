defmodule Karn.Output do
  @moduledoc """
  Defines the contract for receiving messages from the LLM .
  By default uses the IO implementation 
  """
  @callback send_response(message :: String.t()) :: :ok

  @callback send_error(message :: String.t()) :: :ok

  @callback send_blocks(messages :: list(map())) :: :ok | {:error, String.t()}

  @callback send_usage(data :: map()) :: :ok | {:error, String.t()}

  @callback send_state(data :: struct()) :: :ok | {:error, String.t()}

  def send_response(message), do: impl().send_response(message)

  def send_error(message), do: impl().send_error(message)

  def send_blocks(messages), do: impl().send_blocks(messages)

  def send_usage(data), do: impl().send_usage(data)

  def send_state(data), do: impl().send_state(data)

  defp impl() do
    Application.get_env(:karn, :output, Karn.Output.IO)
  end
end
