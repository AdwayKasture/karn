defmodule Karn.ServerTest do
  use ExUnit.Case, async: false
  import Mox

  # Aliases for the system under test and its mocks/dependencies
  alias ReqLLM.Message.ContentPart
  alias Karn.AI.Models
  alias Karn.{Server, State}
  alias Karn.Test.OutputMessenger
  alias Karn.LLMAdapterMock
  alias ReqLLM.{Response, Message, Context}

  # Ensure Mox expectations are checked.
  setup :set_mox_from_context
  setup :verify_on_exit!

  # Set the test process as the receiver for the Output Messenger.
  setup do
    Application.put_env(:karn, :test_receiver_pid, self())
    :ok
  end

  # --- Explain Handling ---

  describe "Explain Handling (:explain)" do
    setup do
      {:ok, pid} = start_supervised({Server, [name: Server]})
      # Consume the initial greeting
      assert_receive {:response, _}

      # Stub the LLM Adapter for the subsequent calls
      stub(LLMAdapterMock, :generate_text, fn _, _ ->
        {:ok, mock_llm_response("Explanation complete.", %{input_tokens: 100, output_tokens: 50})}
      end)

      {:ok, %{pid: pid}}
    end

    test "successfully explains module with references", %{pid: pid} do
      module = Karn.Server
      refs = [Karn.State]
      query = "Why did you use handle_info(:start)?"

      # 2. Call the server
      assert Karn.e(module, refs, query) == :done

      # 3. Assert response and usage
      assert_receive {:response, "Explanation complete."}

      GenServer.call(pid, :usage)
      assert_receive {:usage, usage_map}
      assert usage_map[Models.default()].input_tokens == 100
      assert usage_map[Models.default()].output_tokens == 50
    end

    # TODO handle explain fail case 
  end

  # --- Control Calls ---

  describe "Control and View Calls" do
    setup do
      {:ok, pid} = start_supervised({Server, [name: Server]})

      assert_receive {:response, _}

      # Pre-populate state for testing view/reset
      expect(LLMAdapterMock, :generate_text, fn _, _ ->
        {:ok, mock_llm_response("Pre-filled response", %{input_tokens: 5, output_tokens: 5})}
      end)

      Karn.q("A test query")
      assert_receive {:response, _}

      {:ok, %{pid: pid}}
    end

    test ":usage call sends usage data", %{pid: pid} do
      assert Karn.usage() == :done
      assert_receive {:usage, usage_map}
      assert usage_map[Models.default()].input_tokens == 5
    end

    test ":view_context call sends context blocks", %{pid: pid} do
      assert Karn.view_context() == :done
      assert_receive {:blocks, messages}
      # System, User, Assistant
      assert length(messages) == 3
    end

    test ":reset_context resets context to base prompt", %{pid: pid} do
      assert Karn.reset_context() == :done

      Karn.view_context()
      assert_receive {:blocks, messages}
      # Only the system prompt remains
      assert length(messages) == 1
      assert Enum.at(messages, 0).role == :system
    end

    test ":switch_model with valid model updates state", %{pid: pid} do
      assert Karn.switch_model("openai:gpt-4") == :ok

      Karn.view_state()
      assert_receive {:state, state}
      assert state.model == "openai:gpt-4"
    end

    test ":switch_model with invalid model sends error and keeps state", %{pid: pid} do
      assert Karn.switch_model("invalid:model") == :ok

      # Assuming error message from Models.valid
      assert_receive {:error, "invalid is not a recognised provider."}

      # Assert state did not change
      Karn.view_state()
      assert_receive {:state, new_state}
      assert new_state.model == Models.default()
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
