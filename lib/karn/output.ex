defmodule Karn.Output do
  @moduledoc """
  Defines the contract for sending and receiving messages for the chat process.
  """
  @callback send_response(message :: String.t()) :: :ok

  @callback send_error(message :: String.t()) :: :ok

  # TODO formalise when decided 
  @callback send_blocks(messages :: list(map())) :: :ok | {:error, String.t()}

  @callback send_usage(data :: map()) :: :ok | {:error, String.t()}
end
