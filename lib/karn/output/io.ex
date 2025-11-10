defmodule Karn.Output.IO do
  alias ReqLLM.Context
  alias Karn.State
  alias Karn.Output
  @behaviour Output

  @moduledoc """
  Sends messages from the LLM to IO (Iex)
  """

  @impl Output
  def send_response(message) do
    print_block(:assistant, message)
  end

  @impl Output
  def send_error(message) do
    print_block(:error, message)
  end

  @impl Output
  def send_blocks(messages) do
    Enum.each(messages, fn %{role: role, text: text} -> print_block(role, text) end)
    :ok
  end

  @impl Output
  def send_usage(usage) do
    print_usage_per_model(usage, get_width())
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
    print_usage_per_model(state.usage, get_width())
    :ok
  end

  defp get_width do
    case :io.columns() do
      {:ok, width} when is_integer(width) and width > 0 -> width
      _ -> 80
    end
  end

  defp print_usage_per_model(usage_map, width) when is_map(usage_map) do
    box_width = width - 2
    content_width = box_width - 2

    Enum.each(usage_map, fn {model_name, stats} ->
      title = " Usage for #{model_name} "

      IO.puts("╭─" <> title <> String.duplicate("─", box_width - 1 - String.length(title)) <> "╮")

      lines = [
        "  Input tokens:      #{stats.input_tokens}",
        "  Output tokens:     #{stats.output_tokens}",
        "  Cached tokens:     #{stats.cached_tokens}",
        "  Reasoning tokens:  #{stats.reasoning_tokens}",
        "  Total tokens:      #{stats.total_tokens}",
        String.duplicate("─", content_width),
        "  Total Cost:   $#{format_num(stats.total_cost)}",
        "  Input Cost:   $#{format_num(stats.input_cost)}",
        "  Output Cost:  $#{format_num(stats.output_cost)}"
      ]

      Enum.each(lines, fn line ->
        padding = content_width - String.length(line)
        IO.puts("│ " <> line <> String.duplicate(" ", padding) <> " │")
      end)

      IO.puts("╰" <> String.duplicate("─", box_width) <> "╯")
    end)

    :ok
  end

  defp print_block(role, text) do
    width = get_width()
    box_width = width - 2
    content_width = box_width - 2

    title = " #{role} "
    IO.puts("╭─" <> title <> String.duplicate("─", box_width - 1 - String.length(title)) <> "╮")

    text
    |> String.split("\n")
    |> Enum.each(fn line ->
      wrapped_lines = wrap(line, content_width)

      Enum.each(wrapped_lines, fn wrapped_line ->
        padding = content_width - String.length(wrapped_line)
        IO.puts("│ " <> wrapped_line <> String.duplicate(" ", padding) <> " │")
      end)
    end)

    IO.puts("╰" <> String.duplicate("─", box_width) <> "╯")
  end

  # credo:disable-for-next-line
  defp wrap(text, max_len) do
    if String.length(text) <= max_len do
      [text]
    else
      words = String.split(text, " ")

      {lines, last_line} =
        Enum.reduce(words, {[], ""}, fn word, {acc, line} ->
          cond do
            # 1. Start a new line (line is empty)
            line == "" ->
              {acc, word}

            # 2. Check if the word is too long for the current line
            String.length(line <> " " <> word) > max_len ->
              # Finish the current line and start a new one with the word
              {[line | acc], word}

            # 3. Append the word to the current line
            true ->
              {acc, line <> " " <> word}
          end
        end)

      # handle words longer than max_len
      [last_line | lines]
      |> Enum.reverse()
      |> Enum.flat_map(fn line ->
        if String.length(line) < max_len do
          [line]
        else
          String.graphemes(line)
          |> Enum.chunk_every(max_len)
          |> Enum.map(&Enum.join/1)
        end
      end)
    end
  end

  defp format_num(d), do: :erlang.float_to_binary(d, decimals: 8)
end
