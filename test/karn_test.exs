defmodule KarnTest do
  use ExUnit.Case
  doctest Karn

  test "greets the world" do
    assert Karn.hello() == :world
  end
end
