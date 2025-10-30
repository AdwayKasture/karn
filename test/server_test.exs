defmodule Karn.ServerTest do
  use ExUnit.Case, async: false
  import Mox

  # Ensure Mox expectations are checked.
  setup :set_mox_from_context
  setup :verify_on_exit!

  # Set the test process as the receiver for the Output Messenger.
  setup do
    Application.put_env(:karn, :test_receiver_pid, self())
    :ok
  end

  # All specific tests have been moved to more appropriate files:
  # - context_test.exs for context management
  # - explain_test.exs for explain functionality
  # - server_models_test.exs for model switching
  # - usage_test.exs for usage tracking

  # This file is kept for any future generic server tests.
end
