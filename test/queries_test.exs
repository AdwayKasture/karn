defmodule Karn.QueriesTest do
  use ExUnit.Case, async: false
  import Mox
  alias Karn.AI.Models
  alias ReqLLM.{Response, Message, Context}
  alias ReqLLM.Message.ContentPart
  alias Karn.Server
  alias Karn.LLMAdapterMock

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

    test "handles successful query and updates state", %{pid: pid} do
      user_query = "What is a GenServer?"
      llm_response_text = "A GenServer is a fundamental building block in Elixir."
      llm_response = mock_llm_response(llm_response_text, %{input_tokens: 5, output_tokens: 10})
      model = Models.default()

      expect(LLMAdapterMock, :generate_text, 1, fn ^model, context_list ->
        {:ok, llm_response}
      end)

      assert Karn.q(user_query) == :done

      assert_receive {:response, llm_response_text}

      Karn.usage()
      assert_receive {:usage, usage_map}
      assert usage_map[model].input_tokens == 5
      assert usage_map[model].output_tokens == 10
    end

    test "handles LLM validation error and sends error output", %{pid: pid} do
      error_reason = "Context size exceeded."
      mock_error = %ReqLLM.Error.Validation.Error{reason: error_reason}

      expect(LLMAdapterMock, :generate_text, 1, fn _, _ -> {:error, mock_error} end)

      assert Karn.q("Too long query") == :done

      assert_receive {:error, error_reason}
    end

    test "handles API request error and sends error output", %{pid: pid} do
      error_reason = "Time out"
      mock_error = %ReqLLM.Error.API.Request{reason: "Time out", status: 400}

      expect(LLMAdapterMock, :generate_text, 1, fn _, _ -> {:error, mock_error} end)

      assert Karn.q("Too long query") == :done

      assert_receive {:error, error_reason}
    end

    test "handles unknown error and sends error output", %{pid: pid} do
      error_reason = "asdfjalfdk"

      expect(LLMAdapterMock, :generate_text, 1, fn _, _ -> {:error, error_reason} end)

      assert Karn.q("Too long query") == :done

      assert_receive {:error, error_reason}
    end

    # TODO 
    test "state is same after error" do
    end
  end

  defp mock_llm_response(text, usage \\ %{input_tokens: 10, output_tokens: 20}) do
    mock_message = %Message{
      role: :assistant,
      content: [%ContentPart{type: :text, text: text}]
    }

    # Placeholder for a minimal Context struct:
    mock_context = %Context{
      # Add necessary fields for your Context struct here
    }

    %Response{
      # ---------- Core ----------
      id: "mock_res_id_123",
      model: "mock:test-model",
      context: mock_context,
      message: mock_message,
      object: nil,

      # ---------- Streams ----------
      stream?: false,
      stream: nil,

      # ---------- Metadata ----------
      usage: usage,
      finish_reason: :stop,
      provider_meta: %{duration_ms: 100},

      # ---------- Errors ----------
      error: nil
    }
  end
end
