defmodule Karn.ServerModelsTest do
  use ExUnit.Case, async: false
  import Mox
  alias Karn.AI.Models
  alias Karn.Server
  alias Karn.LLMAdapterMock
  import Karn.Test.Fixtures

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    Application.put_env(:karn, :test_receiver_pid, self())
    :ok
  end

  describe "Model Switching" do
    setup do
      {:ok, pid} = start_supervised({Server, [name: Server]})
      assert_receive {:response, _}
      {:ok, %{pid: pid}}
    end

    test ":switch_model with valid model updates state", %{pid: _pid} do
      new_model = "openai:gpt-4"
      assert Karn.switch_model(new_model) == :ok

      Karn.view_state()
      assert_receive {:state, state}
      assert state.model == new_model

      llm_response = mock_llm_response("Test response")

      expect(LLMAdapterMock, :generate_text, 1, fn ^new_model, _context_list ->
        {:ok, llm_response}
      end)

      assert Karn.q("Test query") == :done
      assert_receive {:response, "Test response"}
    end

    test ":switch_model with invalid model sends error and keeps state", %{pid: _pid} do
      initial_model = Models.default()
      invalid_model = "invalid:model"

      assert Karn.switch_model(invalid_model) == :ok

      assert_receive {:error, "invalid is not a recognised provider."}

      Karn.view_state()
      assert_receive {:state, state}
      assert state.model == initial_model

      llm_response = mock_llm_response("Test response")

      expect(LLMAdapterMock, :generate_text, 1, fn ^initial_model, _context_list ->
        {:ok, llm_response}
      end)

      assert Karn.q("Test query") == :done
      assert_receive {:response, "Test response"}
    end

    test ":reset_model switches back to the default model", %{pid: _pid} do
      # First, switch to a different model
      assert Karn.switch_model("openai:gpt-4") == :ok
      Karn.view_state()
      assert_receive {:state, state}
      assert state.model == "openai:gpt-4"

      # Now, reset it
      assert Karn.reset_model() == :ok

      Karn.view_state()
      assert_receive {:state, new_state}
      assert new_state.model == Models.default()

      default_model = Models.default()
      llm_response = mock_llm_response("Test response")

      expect(LLMAdapterMock, :generate_text, 1, fn ^default_model, _context_list ->
        {:ok, llm_response}
      end)

      assert Karn.q("Test query") == :done
      assert_receive {:response, "Test response"}
    end
  end
end
