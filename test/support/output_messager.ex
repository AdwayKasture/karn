defmodule Karn.Test.OutputMessenger do
  @moduledoc """
  An implementation of Karn.Output that sends messages directly
  to a configured test process PID, enabling the use of assert_receive.
  """
  @behaviour Karn.Output

  # Retrieves the PID configured to receive messages from the Application Env
  defp receiver_pid, do: Application.get_env(:karn, :test_receiver_pid)

  # --- Implementations for Karn.Output Behaviour ---

  @impl Karn.Output
  def send_response(message) do
    send(receiver_pid(), {:response, message})
    :ok
  end

  @impl Karn.Output
  def send_error(message) do
    send(receiver_pid(), {:error, message})
    :ok
  end

  # Implement the rest of the callbacks similarly:
  @impl Karn.Output
  def send_blocks(messages) do
    send(receiver_pid(), {:blocks, messages})
    :ok
  end

  @impl Karn.Output
  def send_usage(data) do
    send(receiver_pid(), {:usage, data})
    :ok
  end

  @impl Karn.Output
  def send_state(data) do
    send(receiver_pid(), {:state, data})
    :ok
  end
end
