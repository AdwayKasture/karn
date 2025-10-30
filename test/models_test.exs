defmodule Karn.AI.ModelsTest do
  use ExUnit.Case
  alias Karn.AI.Models

  describe "default/0" do
    test "returns the default model" do
      assert Models.default() == "google:gemini-2.0-flash"
    end
  end

  describe "valid/1" do
    test "returns :ok for a valid model" do
      assert Models.valid("anthropic:claude-sonnet-4-5-20250929") == :ok
    end

    test "invalid format" do
      assert Models.valid("aa") ==
               {:error,
                "model must be in format provider:model like #{"google:gemini-2.0-flash"}"}
    end

    test "invalid provider" do
      assert Models.valid("poogle:gemini-2.0-flash") == {:error, "No such provider exists"}
    end

    test "valid provider and invalid model" do
      assert Models.valid("google:invalid_model") ==
               {:error,
                "Only gemini-flash-latest\ngemini-embedding-001\ngemini-2.5-pro\ngemini-2.5-flash-preview-05-20\ngemini-2.5-flash\ngemini-2.0-flash-lite\ngemini-2.0-flash\n are supported. You provided: invalid_model"}
    end
  end
end
