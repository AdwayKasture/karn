defmodule Karn.AI.IntrospectTest do
  use ExUnit.Case, async: true

  alias Karn.AI.Introspect

  describe "module/1" do
    test "returns the source code for a project module" do
      assert {:ok, source} = Introspect.module(Karn.AI.Introspect)
      assert source |> String.starts_with?("defmodule Karn.AI.Introspect do")
    end

    test "returns a specific message for a standard library module" do
      assert {:ok, "Elixir.Enum from std lib of elixir"} == Introspect.module(Enum)
    end

    test "returns an error for a non-existent module" do
      assert {:error, "Invalid module provided"} == Introspect.module(NonExistentModule)
    end

    test "returns an error for an atom that is not a module" do
      assert {:error, "Invalid module provided"} == Introspect.module(:not_a_real_module)
    end
  end

  describe "module?/1" do
    test "returns true for an existing module" do
      assert Introspect.module?(Karn.AI.Introspect)
      assert Introspect.module?(Enum)
    end

    test "returns false for a non-existent module" do
      refute Introspect.module?(NonExistentModule)
    end

    test "returns false for an atom that is not a module" do
      refute Introspect.module?(:not_a_real_module)
    end
  end
end
