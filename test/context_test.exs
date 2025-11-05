defmodule Karn.ContextTest do
  use ExUnit.Case, async: false
  import Mox
  alias Karn.Server
  alias Karn.AI.Prompts
  alias Karn.LLMAdapterMock
  import Karn.Test.Fixtures

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    Application.put_env(:karn, :test_receiver_pid, self())
    :ok
  end

  describe "Context Handling" do
    setup do
      {:ok, pid} = start_supervised({Server, [name: Server]})
      p = Prompts.start_prompt()
      assert_receive {:response, ^p}
      {:ok, %{pid: pid}}
    end

    test "view_context shows initial context", %{pid: _pid} do
      assert Karn.view_context() == :done
      assert_receive {:blocks, messages}
      assert length(messages) == 1
      assert Enum.at(messages, 0).role == :system
    end

    test "context accumulates after a query", %{pid: _pid} do
      expect(LLMAdapterMock, :generate_text, fn _, _ ->
        {:ok, mock_llm_response("Response", %{})}
      end)

      Karn.q("Query")
      assert_receive {:response, "Response"}

      assert Karn.view_context() == :done
      assert_receive {:blocks, messages}
      # System, User, Assistant
      assert length(messages) == 3
      assert Enum.at(messages, 1).role == :user
      assert Enum.at(messages, 1).text == "Query"
      assert Enum.at(messages, 2).role == :assistant
      assert Enum.at(messages, 2).text == "Response"
    end

    test "reset_context reverts to the base system prompt", %{pid: _pid} do
      expect(LLMAdapterMock, :generate_text, fn _, _ ->
        {:ok, mock_llm_response("Response", %{})}
      end)

      Karn.q("Query")
      assert_receive {:response, "Response"}

      assert Karn.reset_context() == :done

      assert Karn.view_context() == :done
      assert_receive {:blocks, messages}
      assert length(messages) == 1
      assert Enum.at(messages, 0).role == :system
    end

    test "reset_context with a custom system prompt", %{pid: _pid} do
      assert Karn.reset_context("You are a helpful bot.") == :done

      assert Karn.view_context() == :done
      assert_receive {:blocks, messages}
      assert length(messages) == 1
      assert Enum.at(messages, 0).text == "You are a helpful bot."
    end
  end
end
