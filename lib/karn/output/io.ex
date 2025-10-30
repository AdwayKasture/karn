defmodule Karn.Output.IO do
  alias ReqLLM.Context
  alias Karn.State
  alias Karn.Output
  @behaviour Output

  @impl Output
  def send_response(message) do
    IO.puts(message)
  end

  @impl Output
  def send_error(message) do
    IO.puts(message)
  end

  @impl Output
  def send_blocks(messages) do
    Enum.map(messages, fn %{role: role, text: text} -> print_block(role, text) end)
    :ok
  end

  @impl Output
  def send_usage(usage) do
    print_usage_per_model(usage)
  end

  @impl Output
  def send_state(state) when is_struct(state, State) do
    blocks =
      state.context
      |> Context.to_list()
      |> Enum.map(fn m ->
        [content] = m.content
        %{role: m.role, text: content.text}
      end)

    send_blocks(blocks)
    IO.puts("model: #{state.model}")
    print_usage_per_model(state.usage)
    :ok
  end

  defp print_usage_per_model(usage_map) when is_map(usage_map) do
    Enum.each(usage_map, fn {model_name, stats} ->
      IO.puts("======================================================")
      IO.puts("Model: #{model_name}")
      IO.puts("------------------------------------------------------")
      IO.puts(~s|  Input tokens:      #{stats.input_tokens}|)
      IO.puts(~s|  Output tokens:     #{stats.output_tokens}|)
      IO.puts(~s|  Cached tokens:     #{stats.cached_tokens}|)
      IO.puts(~s|  Reasoning tokens:  #{stats.reasoning_tokens}|)
      IO.puts(~s|  Total tokens:      #{stats.total_tokens}|)
      IO.puts("======================================================")
      IO.puts(~s|  Total Cost:   $#{format_num(stats.total_cost)}|)
      IO.puts(~s|  Input Cost:   $#{format_num(stats.input_cost)}|)
      IO.puts(~s|  Output Cost:  $#{format_num(stats.output_cost)}|)
    end)

    IO.puts("======================================================")
    :ok
  end

  defp print_block(role, text) do
    IO.puts("#{role}:")
    IO.puts(text)
    IO.puts("------------------------------------------------------")
  end

  defp format_num(d), do: :erlang.float_to_binary(d, decimals: 8)
end
