Mox.defmock(Karn.LLMAdapterMock, for: Karn.LLMAdapter)
Application.put_env(:karn, :llm_adapter, Karn.LLMAdapterMock)

Application.put_env(:karn, :output, Karn.Test.OutputMessenger)

ExUnit.start()
