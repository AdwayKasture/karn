defmodule Karn.Test.Fixtures do
  alias ReqLLM.{Response, Message, Context}
  alias ReqLLM.Message.ContentPart

  @moduledoc false

  def mock_llm_response(text, usage \\ %{}) do
    mock_message = %Message{
      role: :assistant,
      content: [%ContentPart{type: :text, text: text}]
    }

    # Placeholder for a minimal Context struct:
    mock_context = %Context{
      # Add necessary fields for your Context struct here
    }

    %Response{
      # ---------- Core ----------
      id: "mock_res_id_123",
      model: "mock:test-model",
      context: mock_context,
      message: mock_message,
      object: nil,

      # ---------- Streams ----------
      stream?: false,
      stream: nil,

      # ---------- Metadata ----------
      usage: usage,
      finish_reason: :stop,
      provider_meta: %{duration_ms: 100},

      # ---------- Errors ----------
      error: nil
    }
  end
end
