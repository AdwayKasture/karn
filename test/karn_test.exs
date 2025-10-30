defmodule KarnTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  import Mox

  # TODO 
  # process sleep added as IO is async and might have race condition
  # might be better to have a test "Output" to validate if message is recieved
  # @describe_tag :server
  describe "starting and stopping server" do
    test "start server" do
      assert capture_io(fn ->
               {:ok, _pid} = Karn.start()
               Process.sleep(100)
             end) == "Ask your elixir query\n"
    end

    test "start with valid model" do
      assert capture_io(fn ->
               {:ok, _pid} = Karn.start(model: "anthropic:claude-sonnet-4-5-20250929")
               Process.sleep(100)
             end) == "Ask your elixir query\n"
    end

    test "start with invalid model" do
      assert capture_io(fn ->
               :ok = Karn.start(model: "aa:claude-4.0")
               Process.sleep(100)
             end) == "aa is not a recognised provider.\n"
    end

    test "duplicate start fails" do
      {:ok, pid} = Karn.start()
      assert Karn.start() == {:error, {:already_started, pid}}
    end

    test "stop" do
      data =
        capture_io(fn ->
          Karn.start()
          Karn.stop()
        end)

      assert String.contains?(data, "Model: google:gemini")
    end
  end
end
