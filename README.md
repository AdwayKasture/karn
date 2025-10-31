# Karn

Karn is an interactive AI assistant for your Elixir codebase, designed to be used within an `IEx` session. It helps you understand and query your code using natural language, leveraging the power of Large Language Models.

## Features

*   **Natural Language Queries**: Ask questions about your code in plain English.
*   **Code Explanations**: Get detailed explanations for specific modules and their functions.
*   **Conversational Context**: Karn remembers the history of your conversation, allowing for follow-up questions.
*   **Context Management**: View the current conversation context or reset it when needed.
*   **Usage Tracking**: Monitor your LLM token usage for the current session.

## Installation

Add `karn` as a dependency to your `mix.exs` file. It is recommended to add it only for the `:dev` environment.

```elixir
def deps do
  [
    {:karn, "~> 0.1.0", only: [:dev]}
  ]
end
```

Then, fetch the dependencies:

```shell
mix deps.get
```

## Todo List

- [x] Multi-model support
- [x] Tests
- [x] Error handling
- [x] Timeouts
- [x] Igniter Installation
- [x] context cachinig
- [ ] docs
- [ ] cleanup
- [ ] default models for common providers
- [ ] upgrade to stable version of reqllm
- [ ] integration tests


## Setup and Usage

Karn is designed to be used interactively within an `IEx` session.

### 1. Start IEx

Start your project's `IEx` session:

```shell
iex -S mix phx.server
#
iex -S mix run
```

### 2. Configure API Key

Karn uses the `ReqLLM` library to communicate with LLMs. You need to provide an API key for the desired service. The default model is `google:gemini-2.0-flash`, so you'll need a Google AI API key.

You can configure your key in one of two ways:

1.  **Environment Variable (Recommended)**: Export the key in your shell.
    ```shell
    export GOOGLE_API_KEY="your-google-api-key"
    ```
    `ReqLLM` will automatically pick it up when you start `iex`.

2.  **In your `IEx` session**: Configure the key manually.
    ```elixir
    # Replace "your-google-api-key" with your actual key
    ReqLLM.put_key(:google_api_key, "your-google-api-key")
    ```

### 3. Start the Karn Server

Start the `Karn.Ai.Server` process:

```elixir
Karn.start
```

You should see the message: `"Ask your elixir query"`

### 4. Use Karn

For a more human-friendly experience, import the `Karn.Ai` functions into your `IEx` shell. This allows you to call them directly.

```elixir
iex> import Karn
Karn
```

Now you can interact with the AI.

#### General Query (`q/1`)

Ask any question about Elixir or your project.

```elixir
iex> q "What is the difference between a GenServer and an Agent?"
```

#### Explain Module (`e/3`)

Get an explanation for a specific module. You can also provide related modules for more context.

```elixir
# Get a general explanation of MyModule
iex> e MyModule

# Get a specific explanation of MyModule
iex> e MyModule,"How does function b work?"

iex> e MyModule,[ModuleB],"How are the two modules related"


# Ask a specific question about MyModule, providing another module for context
iex> e MyModule, [MyOtherModule], "How does the main function work?"
```

#### View Conversation Context (`view_context/0`)

See the history of messages (user and assistant) in the current session.

```elixir
iex> view_context()
```

#### Reset Conversation Context (`reset_context/1`)

Clear the current conversation history. You can optionally provide a new system prompt.

```elixir
# Reset to the default system prompt
iex> reset_context()

# Reset with a custom system prompt
iex> reset_context "You are a helpful Elixir assistant."
```

#### View Usage (`usage/0`)

Check the token usage (input, output, and total cost) for the current session.

```elixir
iex> usage()
```

#### Stop Karn (`stop/0`)

Stop the `Karn.Ai.Server`. This will also print the final usage statistics for the session.

```elixir
iex> stop()
```
