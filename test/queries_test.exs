defmodule Karn.QueriesTest do
  use ExUnit.Case, async: false
  import Mox
  alias Karn.AI.Models
  alias Karn.Server
  alias Karn.LLMAdapterMock
  import Karn.Test.Fixtures

  # Ensure Mox expectations are checked.
  setup :set_mox_from_context
  setup :verify_on_exit!

  # Set the test process as the receiver for the Output Messenger.
  setup do
    Application.put_env(:karn, :test_receiver_pid, self())
    :ok
  end

  describe "Query Handling" do
    setup do
      {:ok, pid} = start_supervised({Server, [name: Server]})
      assert_receive {:response, _}
      {:ok, %{pid: pid}}
    end

    test "handles successful query and updates state", %{pid: _pid} do
      user_query = "What is a GenServer?"
      llm_response_text = "A GenServer is a fundamental building block in Elixir."
      llm_response = mock_llm_response(llm_response_text, %{input_tokens: 5, output_tokens: 10})
      model = Models.default()

      expect(LLMAdapterMock, :generate_text, 1, fn ^model, _context_list ->
        {:ok, llm_response}
      end)

      assert Karn.q(user_query) == :done

      assert_receive {:response, ^llm_response_text}

      Karn.usage()
      assert_receive {:usage, usage_map}
      assert usage_map[model].input_tokens == 5
      assert usage_map[model].output_tokens == 10
    end

    test "handles LLM validation error and sends error output", %{pid: _pid} do
      error_reason = "Context size exceeded."
      mock_error = %ReqLLM.Error.Validation.Error{reason: error_reason}

      expect(LLMAdapterMock, :generate_text, 1, fn _, _ -> {:error, mock_error} end)

      assert Karn.q("Too long query") == :done

      assert_receive {:error, ^error_reason}
    end

    test "handles API request error and sends error output", %{pid: _pid} do
      mock_error = %ReqLLM.Error.API.Request{reason: "Time out", status: 400}

      expect(LLMAdapterMock, :generate_text, 1, fn _, _ -> {:error, mock_error} end)

      assert Karn.q("Too long query") == :done

      assert_receive {:error, "Failed to make query due to Time out, with status code 400"}
    end

    test "handles unknown error and sends error output", %{pid: _pid} do
      error_reason = "asdfjalfdk"

      expect(LLMAdapterMock, :generate_text, 1, fn _, _ -> {:error, error_reason} end)

      assert Karn.q("Too long query") == :done

      msg = "Failed due to #{error_reason}"

      assert_receive {:error, ^msg}
    end

    test "state is same after error", %{pid: _pid} do
      # 1. Get initial state
      Karn.view_state()
      assert_receive {:state, initial_state}

      # 2. Mock an error response
      mock_error = %ReqLLM.Error.Validation.Error{reason: "Bad request"}
      expect(LLMAdapterMock, :generate_text, 1, fn _, _ -> {:error, mock_error} end)

      # 3. Make the query that will fail
      assert Karn.q("A query that will fail") == :done
      assert_receive {:error, "Bad request"}

      # 4. Get final state and compare
      Karn.view_state()
      assert_receive {:state, final_state}

      # The context and model should be unchanged. Usage might change depending on implementation.
      assert initial_state.context == final_state.context
      assert initial_state.model == final_state.model
    end
  end
end
