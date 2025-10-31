defmodule Karn.ExplainTest do
  use ExUnit.Case, async: false
  import Mox
  alias Karn.Server
  alias Karn.LLMAdapterMock
  import Karn.Test.Fixtures

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    Application.put_env(:karn, :test_receiver_pid, self())
    :ok
  end

  describe "Explain Handling" do
    setup do
      {:ok, _pid} = start_supervised({Server, [name: Server]})
      assert_receive {:response, _}

      stub(LLMAdapterMock, :generate_text, fn _, _ ->
        {:ok, mock_llm_response("Explanation complete.", %{})}
      end)

      :ok
    end

    test "e/1 explains a module" do
      assert Karn.e(Karn.AI) == :done
      assert_receive {:response, "Explanation complete."}
    end

    test "e/2 explains a module with a query" do
      assert Karn.e(Karn.AI, "What is this?") == :done
      assert_receive {:response, "Explanation complete."}
      Karn.view_context()
      assert_receive {:blocks, messages}
      # system,module,query,response
      assert length(messages) == 4
    end

    test "e/2 explains a module with a reference" do
      assert Karn.e(Karn.AI, Karn.Server) == :done
      assert_receive {:response, "Explanation complete."}
    end

    test "e/2 explains a module with references" do
      assert Karn.e(Karn.AI, [Karn.Server]) == :done
      assert_receive {:response, "Explanation complete."}
    end

    test "e/2 explains a module with multiple references" do
      assert Karn.e(Karn.AI, [Karn.Server, Karn.AI.Introspect]) == :done
      assert_receive {:response, "Explanation complete."}
      Karn.view_context()
      assert_receive {:blocks, messages}
      # system,module AI,module Server,module Introspect,query,response
      assert length(messages) == 6
    end

    test "e/3 explains a module with references and a query" do
      assert Karn.e(Karn.AI, [Karn.Server], "What is this?") == :done
      assert_receive {:response, "Explanation complete."}
    end

    test "e/3 with non-existent reference module does not fail" do
      assert Karn.e(Karn.AI, [NonExistentModule], "What is this?") == :done
      assert_receive {:response, "Explanation complete."}
    end

    test "e/1 with non-existent module sends an error" do
      assert Karn.e(NonExistentModule) == :done
      assert_receive {:error, "Failed to explain module: Invalid module provided"}
    end

    test "e/1 with existing ref updates the message in context" do
      assert Karn.e(Karn.AI) == :done
      assert_receive {:response, "Explanation complete."}

      assert GenServer.call(Server, :view_state) == :done
      assert_receive {:state, state_before}

      messages_before = state_before.context |> ReqLLM.Context.to_list()

      count_before =
        Enum.count(messages_before, fn msg ->
          msg.metadata && msg.metadata[:ref] == Karn.AI
        end)

      assert count_before == 1

      assert Karn.e(Karn.AI) == :done
      assert_receive {:response, "Explanation complete."}

      assert Karn.view_state() == :done
      assert_receive {:state, state_after}

      messages_after = state_after.context |> ReqLLM.Context.to_list()

      count_after =
        Enum.count(messages_after, fn msg ->
          msg.metadata && msg.metadata[:ref] == Karn.AI
        end)

      assert count_after == 1
    end
  end
end
