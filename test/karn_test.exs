defmodule KarnTest do
  alias Karn.AI.Prompts
  use ExUnit.Case, async: false
  import Mox

  setup :verify_on_exit!

  setup do
    Application.put_env(:karn, :test_receiver_pid, self())
    :ok
  end

  describe "starting and stopping server" do
    test "start server prints the default greeting" do
      {:ok, _pid} = Karn.start()
      p = Prompts.start_prompt()
      assert_receive {:response,^p}
    end

    test "start with valid model prints the default greeting" do
      {:ok, _pid} = Karn.start(model: "anthropic:claude-sonnet-4-5-20250929")
      p = Prompts.start_prompt()
      assert_receive {:response, ^p}
    end

    test "start with invalid model sends an error" do
      :ok = Karn.start(model: "aa:claude-4.0")
      assert_receive {:error, "aa is not a recognised provider."}
    end

    test "duplicate start fails" do
      {:ok, pid} = Karn.start()
      assert Karn.start() == {:error, {:already_started, pid}}
    end

    test "stop" do
      Karn.start()
      p =  Karn.AI.Prompts.start_prompt()
      assert_receive {:response,^p}
      Karn.stop()
      assert_receive {:usage, _}
    end
  end
end
