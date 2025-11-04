defmodule Karn.Output.IOTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Karn.Output.IO
  alias Karn.State
  alias ReqLLM.Context

  describe "send_response/1" do
    test "prints the message to IO in a box" do
      output = capture_io(fn -> IO.send_response("Hello, world!") end)
      assert output =~ "╭─ assistant ─"
      assert output =~ "│ Hello, world!"
      assert output =~ "╰"
    end
  end

  describe "send_error/1" do
    test "prints the error message to IO in a box" do
      output = capture_io(fn -> IO.send_error("An error occurred.") end)
      assert output =~ "╭─ error ─"
      assert output =~ "│ An error occurred."
      assert output =~ "╰"
    end
  end

  describe "send_blocks/1" do
    test "prints formatted blocks in boxes" do
      messages = [
        %{role: :user, text: "User query"},
        %{role: :assistant, text: "Assistant response"}
      ]

      output = capture_io(fn -> IO.send_blocks(messages) end)
      assert output =~ "╭─ user ─"
      assert output =~ "│ User query"
      assert output =~ "╭─ assistant ─"
      assert output =~ "│ Assistant response"
    end
  end

  describe "send_usage/1" do
    test "prints formatted usage statistics for multiple models in boxes" do
      usage_map = %{
        "model-1" => %{
          input_tokens: 10,
          output_tokens: 20,
          cached_tokens: 5,
          reasoning_tokens: 2,
          total_tokens: 37,
          total_cost: 0.001,
          input_cost: 0.0005,
          output_cost: 0.0005
        },
        "model-2" => %{
          input_tokens: 100,
          output_tokens: 200,
          cached_tokens: 50,
          reasoning_tokens: 20,
          total_tokens: 370,
          total_cost: 0.01,
          input_cost: 0.005,
          output_cost: 0.005
        }
      }

      output = capture_io(fn -> IO.send_usage(usage_map) end)

      assert output =~ "╭─ Usage for model-1 ─"
      assert output =~ "│   Input tokens:      10"
      assert output =~ "│   Total Cost:   $0.00100000"
      assert output =~ "╭─ Usage for model-2 ─"
      assert output =~ "│   Input tokens:      100"
      assert output =~ "│   Total Cost:   $0.01000000"
      assert output =~ "╰"
    end
  end

  describe "send_state/1" do
    test "prints the full state including context, model, and usage in boxes" do
      context =
        Context.new()
        |> Context.append(Context.system("System prompt"))
        |> Context.append(Context.user("User query"))

      state = %State{
        context: context,
        model: "test-model",
        usage: %{
          "test-model" => %{
            input_tokens: 1,
            output_tokens: 2,
            cached_tokens: 0,
            reasoning_tokens: 0,
            total_tokens: 3,
            total_cost: 0.0,
            input_cost: 0.0,
            output_cost: 0.0
          }
        }
      }

      output = capture_io(fn -> IO.send_state(state) end)

      # Check for context blocks
      assert output =~ "╭─ system ─"
      assert output =~ "│ System prompt"
      assert output =~ "╭─ user ─"
      assert output =~ "│ User query"
      # Check for model
      assert output =~ "model: test-model"
      # Check for usage
      assert output =~ "╭─ Usage for test-model ─"
      assert output =~ "│   Input tokens:      1"
    end
  end
end
