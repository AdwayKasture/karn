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

  # --- Tests ---

  describe "Initialization and Startup" do
    test "start_link initializes state and sends a greeting" do
      {:ok, pid} = Server.start_link([])

      assert_receive {:response, "Ask your elixir query"}

      GenServer.call(pid, :view_state)
      assert_receive {:state, expected_state}

      assert expected_state.model == Models.default()
      assert expected_state.usage[Models.default()].input_tokens == 0

      GenServer.stop(pid)
    end
  end

  # --- Query Handling ---

  describe "Query Handling (:query)" do
    setup do
      {:ok, pid} = start_supervised(Server)
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

      assert GenServer.call(pid, {:query, user_query}) == :done

      assert_receive {:response, llm_response_text}

      GenServer.call(pid, :usage)
      assert_receive {:usage, usage_map}
      assert usage_map[model].input_tokens == 5
      assert usage_map[model].output_tokens == 10
    end

    test "handles LLM validation error and sends error output", %{pid: pid} do
      error_reason = "Context size exceeded."
      mock_error = %ReqLLM.Error.Validation.Error{reason: error_reason}

      expect(LLMAdapterMock, :generate_text, 1, fn _, _ -> {:error, mock_error} end)

      assert GenServer.call(pid, {:query, "Too long query"}) == :done

      assert_receive {:error, error_reason}
    end
  end

  # --- Explain Handling ---

  describe "Explain Handling (:explain)" do
    setup do
      {:ok, pid} = start_supervised(Server)
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
      assert GenServer.call(pid, {:explain, module, refs, query}) == :done

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
      {:ok, pid} = start_supervised(Server)
      assert_receive {:response, _}

      # Pre-populate state for testing view/reset
      expect(LLMAdapterMock, :generate_text, fn _, _ ->
        {:ok, mock_llm_response("Pre-filled response", %{input_tokens: 5, output_tokens: 5})}
      end)

      GenServer.call(pid, {:query, "A test query"})
      assert_receive {:response, _}

      {:ok, %{pid: pid}}
    end

    test ":usage call sends usage data", %{pid: pid} do
      assert GenServer.call(pid, :usage) == :done
      assert_receive {:usage, usage_map}
      assert usage_map[Models.default()].input_tokens == 5
    end

    test ":view_context call sends context blocks", %{pid: pid} do
      assert GenServer.call(pid, :view_context) == :done
      assert_receive {:blocks, messages}
      # System, User, Assistant
      assert length(messages) == 3
    end

    test ":reset_context resets context to base prompt", %{pid: pid} do
      assert GenServer.call(pid, {:reset_context, nil}) == :done

      GenServer.call(pid, :view_context)
      assert_receive {:blocks, messages}
      # Only the system prompt remains
      assert length(messages) == 1
      assert Enum.at(messages, 0).role == :system
    end

    test ":switch_model with valid model updates state", %{pid: pid} do
      assert GenServer.call(pid, {:switch_model, "openai:gpt-4"}) == :ok

      GenServer.call(pid, :view_state)
      assert_receive {:state, state}
      assert state.model == "openai:gpt-4"
    end

    test ":switch_model with invalid model sends error and keeps state", %{pid: pid} do
      original_state = GenServer.call(pid, :view_state)
      # Consume view_state message
      assert_receive {:state, _}

      assert GenServer.call(pid, {:switch_model, "invalid:model"}) == :ok

      # Assuming error message from Models.valid
      assert_receive {:error, "invalid is not a recognised provider."}

      # Assert state did not change
      GenServer.call(pid, :view_state)
      assert_receive {:state, new_state}
      assert new_state.model == Models.default()
    end
  end
end
