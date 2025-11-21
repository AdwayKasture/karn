defmodule Karn.MultipleQueriesTest do
  use ExUnit.Case, async: false
  import Mox
  alias Karn.AI.Models
  alias Karn.Server
  alias Karn.LLMAdapterMock
  import Karn.Test.Fixtures
  @moduletag :integ

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    Application.put_env(:karn, :test_receiver_pid, self())
    :ok
  end

  # Define operation types for extensible scenarios
  @type operation :: :query | :explain | :usage | :view_state | :view_context
  @type scenario :: [operation]

  defp execute_operation(:query, opts) when is_list(opts) do
    query_text = Keyword.get(opts, :text, "What is this?")
    assert Karn.q(query_text) == :done
    assert_receive {:response, _response}
    refute_receive {:error, _error}
  end

  defp execute_operation(:query, query_text) when is_binary(query_text) do
    assert Karn.q(query_text) == :done
    assert_receive {:response, _response}
    refute_receive {:error, _error}
  end

  defp execute_operation(:explain, opts) when is_list(opts) do
    module = Keyword.get(opts, :module, Karn.AI)
    assert Karn.e(module) == :done
    assert_receive {:response, _response}
    refute_receive {:error, _error}
  end

  defp execute_operation(:explain, module) when is_atom(module) do
    assert Karn.e(module) == :done
    assert_receive {:response, _response}
    refute_receive {:error, _error}
  end

  defp execute_operation(:usage, _opts) do
    Karn.usage()
    assert_receive {:usage, _usage_map}
  end

  defp execute_operation(:view_state, _opts) do
    Karn.view_state()
    assert_receive {:state, _state}
  end

  defp execute_operation(:view_context, _opts) do
    Karn.view_context()
    assert_receive {:blocks, _messages}
  end

  # Scenario runner with configurable mocking
  defp run_scenario(scenario, opts \\ []) do
    model = Models.default()
    llm_calls = Keyword.get(opts, :llm_calls, count_llm_calls(scenario))
    response_text = Keyword.get(opts, :response_text, "Response complete.")
    token_usage = Keyword.get(opts, :token_usage, %{input_tokens: 5, output_tokens: 10})

    if llm_calls > 0 do
      expect(LLMAdapterMock, :generate_text, llm_calls, fn ^model, _context_list ->
        {:ok, mock_llm_response(response_text, token_usage)}
      end)
    else
      stub(LLMAdapterMock, :generate_text, fn _, _ ->
        {:ok, mock_llm_response(response_text, token_usage)}
      end)
    end

    Enum.each(scenario, fn op -> execute_operation(op, []) end)

    if llm_calls > 0 do
      verify!()
      assert_usage_matches(model, llm_calls, token_usage)
    end
  end

  defp count_llm_calls(scenario) do
    Enum.count(scenario, fn op -> op in [:query, :explain] end)
  end

  defp assert_usage_matches(model, expected_calls, %{input_tokens: input, output_tokens: output}) do
    Karn.usage()
    assert_receive {:usage, usage_map}
    assert usage_map[model].input_tokens == input * expected_calls
    assert usage_map[model].output_tokens == output * expected_calls
  end

  # Integration scenario runner - uses real LLM without mocking
  defp run_scenario_integration(scenario, _opts \\ []) do
    # Check if API key is available
    case System.get_env("GOOGLE_API_KEY") do
      nil ->
        flunk(
          "GOOGLE_API_KEY environment variable not set. Cannot run integration tests without API key."
        )

      _key ->
        # No mocking - use real LLM
        Enum.each(scenario, fn op -> execute_operation(op, []) end)

        # Allow some time for real LLM responses
        :timer.sleep(3000)
    end
  end

  describe "Basic Scenarios" do
    setup do
      {:ok, _pid} = start_supervised({Server, [name: Server]})
      assert_receive {:response, _}
      :ok
    end

    test "q,q - handles two consecutive queries" do
      run_scenario([:query, :query])
    end

    test "e,e - handles two consecutive explanations" do
      run_scenario([:explain, :explain], llm_calls: 2)
    end

    test "q,e - handles query followed by explanation" do
      run_scenario([:query, :explain])
    end

    test "e,q - handles explanation followed by query" do
      run_scenario([:explain, :query])
    end
  end

  describe "Extended Scenarios" do
    setup do
      {:ok, _pid} = start_supervised({Server, [name: Server]})
      assert_receive {:response, _}
      :ok
    end

    test "query -> usage -> query -> explain" do
      run_scenario([:query, :usage, :query, :explain])
    end

    test "explain -> view_context -> query -> usage -> view_state" do
      run_scenario([:explain, :view_context, :query, :usage, :view_state])
    end

    test "complex workflow with multiple operations" do
      run_scenario([
        :query,
        :usage,
        :view_state,
        :explain,
        :view_context,
        :query,
        :usage,
        :view_state
      ])
    end

    test "usage tracking scenario" do
      run_scenario(
        [
          :query,
          :usage,
          :query,
          :usage,
          :explain,
          :usage
        ],
        token_usage: %{input_tokens: 3, output_tokens: 7}
      )
    end
  end

  describe "Integration Mode Scenarios" do
    @describetag :skip
    setup do
      # Use real LLM adapter instead of mock for integration tests
      Application.put_env(:karn, :llm_adapter, ReqLLM)

      {:ok, _pid} = start_supervised({Server, [name: Server]})
      assert_receive {:response, _}
      :ok
    end

    test "integration workflow 1: basic query and explain cycle" do
      run_scenario_integration([:query, :explain, :usage, :view_state])
    end

    test "integration workflow 2: context building" do
      run_scenario_integration([
        :explain,
        :view_context,
        :query,
        :view_context,
        :usage
      ])
    end

    test "integration workflow 3: state management" do
      run_scenario_integration([
        :view_state,
        :query,
        :view_state,
        :explain,
        :view_state,
        :usage
      ])
    end
  end

  describe "Custom Scenario Helpers" do
    setup do
      {:ok, _pid} = start_supervised({Server, [name: Server]})
      assert_receive {:response, _}
      :ok
    end

    test "custom scenario with parameters" do
      run_scenario(
        [:query, :usage, :explain],
        response_text: "Custom response",
        token_usage: %{input_tokens: 8, output_tokens: 15}
      )
    end

    test "scenario with specific query text" do
      model = Models.default()

      expect(LLMAdapterMock, :generate_text, 2, fn ^model, _context_list ->
        {:ok, mock_llm_response("Specific response", %{input_tokens: 4, output_tokens: 8})}
      end)

      execute_operation(:query, "Specific query text")
      execute_operation(:explain, Karn.Server)

      verify!()
      assert_usage_matches(model, 2, %{input_tokens: 4, output_tokens: 8})
    end
  end
end
