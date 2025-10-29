Mox.defmock(ReqLLMMock,for: Karn.LLMAdapter)
Application.put_env(:karn,:llm_adapter,ReqLLMMock)
ExUnit.start()
