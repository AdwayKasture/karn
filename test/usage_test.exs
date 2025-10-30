defmodule Karn.UsageTest do
  use ExUnit.Case, async: false
  import Mox
  alias Karn.Server
  alias Karn.LLMAdapterMock
  import Karn.Test.Fixtures
  alias Karn.AI.Models

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    Application.put_env(:karn, :test_receiver_pid, self())
    :ok
  end

  describe "Usage Handling" do
    setup do
      {:ok, pid} = start_supervised({Server, [name: Server]})
      assert_receive {:response, _}
      {:ok, %{pid: pid}}
    end

    test "usage accumulates over multiple queries", %{pid: _pid} do
      # First query
      expect(LLMAdapterMock, :generate_text, fn _, _ ->
        {:ok, mock_llm_response("Response 1", %{input_tokens: 10, output_tokens: 20})}
      end)

      Karn.q("Query 1")
      assert_receive {:response, "Response 1"}

      # Second query
      expect(LLMAdapterMock, :generate_text, fn _, _ ->
        {:ok, mock_llm_response("Response 2", %{input_tokens: 5, output_tokens: 15})}
      end)

      Karn.q("Query 2")
      assert_receive {:response, "Response 2"}

      Karn.usage()
      assert_receive {:usage, usage_map}
      model = Models.default()
      assert usage_map[model].input_tokens == 15
      assert usage_map[model].output_tokens == 35
    end

    test "usage is tracked per model", %{pid: _pid} do
      default_model = Models.default()
      other_model = "openai:gpt-4"

      # Query with default model
      expect(LLMAdapterMock, :generate_text, fn _, _ ->
        {:ok, mock_llm_response("Response 1", %{input_tokens: 10, output_tokens: 20})}
      end)

      Karn.q("Query 1")
      assert_receive {:response, "Response 1"}

      # Switch model
      Karn.switch_model(other_model)

      # Query with other model
      expect(LLMAdapterMock, :generate_text, fn _, _ ->
        {:ok, mock_llm_response("Response 2", %{input_tokens: 100, output_tokens: 200})}
      end)

      Karn.q("Query 2")
      assert_receive {:response, "Response 2"}

      Karn.usage()
      assert_receive {:usage, usage_map}

      assert usage_map[default_model].input_tokens == 10
      assert usage_map[default_model].output_tokens == 20
      assert usage_map[other_model].input_tokens == 100
      assert usage_map[other_model].output_tokens == 200
    end
  end
end
