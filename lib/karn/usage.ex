defmodule Karn.Usage do
  alias Karn.Usage
  @moduledoc false

  defstruct input_tokens: 0,
            output_tokens: 0,
            cached_tokens: 0,
            reasoning_tokens: 0,
            total_tokens: 0,
            total_cost: 0.0,
            input_cost: 0.0,
            output_cost: 0.0

  def new(), do: %Usage{}

  def update(usage, data) when is_struct(usage, Usage) do
    fields = Map.keys(usage) |> Enum.reject(&(&1 == :__struct__))

    Enum.reduce(fields, usage, fn field, acc_usage ->
      value_to_add = Map.get(data, field, 0)
      Map.update!(acc_usage, field, &(&1 + value_to_add))
    end)
  end
end
