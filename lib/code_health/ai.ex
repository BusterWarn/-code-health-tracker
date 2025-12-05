defmodule CodeHealth.AI do
  @moduledoc """
  OpenAI integration for code health analysis.
  """

  alias CodeHealth.Spinner

  @doc """
  Call OpenAI API with a prompt and return the response.
  Streams the response for better user experience.
  """
  def chat(prompt, opts \\ []) do
    # Get API key from environment
    api_key = System.get_env("OPENAI_API_KEY")

    unless api_key do
      {:error, "OPENAI_API_KEY environment variable is not set. Please set it with: export OPENAI_API_KEY='sk-...'"}
    else
      json_mode = Keyword.get(opts, :json_mode, false)
      stream = Keyword.get(opts, :stream, true)

      messages = [
        %ExOpenAI.Components.ChatCompletionRequestUserMessage{
          role: :user,
          content: prompt
        }
      ]

      request_opts =
        [
          messages: messages,
          model: "gpt-4o",
          temperature: 0.7,
          max_tokens: 4000
        ]
        |> maybe_add_json_mode(json_mode)
        |> maybe_add_streaming(stream)

      if stream do
        stream_chat(request_opts, api_key)
      else
        call_chat(request_opts, api_key)
      end
    end
  end

  defp maybe_add_json_mode(opts, false), do: opts
  defp maybe_add_json_mode(opts, true) do
    Keyword.put(opts, :response_format, %{type: "json_object"})
  end

  defp maybe_add_streaming(opts, false), do: opts
  defp maybe_add_streaming(opts, true) do
    # Don't add streaming options here, we'll handle it in stream_chat
    opts
  end

  defp call_chat(opts, api_key) do
    # Start spinner
    spinner = Spinner.start("Generating response")

    request_opts =
      opts
      |> Keyword.delete(:messages)
      |> Keyword.delete(:model)
      |> Keyword.put(:api_key, api_key)

    result = case ExOpenAI.Chat.create_chat_completion(
           opts[:messages],
           opts[:model],
           request_opts
         ) do
      {:ok, response} ->
        content =
          response.choices
          |> List.first()
          |> Map.get(:message)
          |> Map.get(:content)

        {:ok, content}

      {:error, error} ->
        {:error, "OpenAI API error: #{inspect(error)}"}
    end

    # Stop spinner
    Spinner.stop(spinner)

    result
  end

  defp stream_chat(opts, api_key) do
    # Start spinner - will be stopped when first content arrives
    spinner = Spinner.start("Waiting for response")

    # Track if we've received first chunk
    first_chunk = Agent.start_link(fn -> true end)

    # Create a callback function that will be called for each chunk
    callback = fn
      :finish ->
        :ok

      {:data, %ExOpenAI.Components.CreateChatCompletionResponse{choices: choices}} ->
        # Stop spinner on first chunk
        if elem(first_chunk, 1) |> Agent.get_and_update(fn state -> {state, false} end) do
          Spinner.stop(spinner)
        end

        choices
        |> Enum.each(fn choice ->
          case choice do
            %{delta: %{content: content}} when not is_nil(content) ->
              IO.write(content)

            _ ->
              :ok
          end
        end)

      {:error, err} ->
        Spinner.stop(spinner)
        IO.puts("\nError: #{inspect(err)}")
    end

    request_opts =
      opts
      |> Keyword.delete(:messages)
      |> Keyword.delete(:model)
      |> Keyword.put(:api_key, api_key)
      |> Keyword.put(:stream, true)
      |> Keyword.put(:stream_to, callback)

    case ExOpenAI.Chat.create_chat_completion(
           opts[:messages],
           opts[:model],
           request_opts
         ) do
      {:ok, _ref} ->
        # Wait for the stream to complete
        # The callback handles all the output
        # We need to wait for the HTTP request to finish
        Process.sleep(100)
        result = wait_for_stream_completion()

        # Make sure spinner is stopped
        if Process.alive?(elem(spinner, 1)) do
          Spinner.stop(spinner)
        end

        # Clean up agent
        Agent.stop(elem(first_chunk, 1))

        result

      {:error, error} ->
        Spinner.stop(spinner)
        Agent.stop(elem(first_chunk, 1))
        {:error, "OpenAI API error: #{inspect(error)}"}
    end
  end

  defp wait_for_stream_completion(retries \\ 600) do
    # Wait up to 60 seconds (600 * 100ms)
    if retries > 0 do
      Process.sleep(100)
      wait_for_stream_completion(retries - 1)
    else
      IO.puts("")
      {:ok, ""}
    end
  end

  @doc """
  Parse JSON response from OpenAI, handling potential markdown formatting.
  """
  def parse_json_response(response) do
    # Remove markdown code blocks if present
    cleaned =
      response
      |> String.replace(~r/^```json\s*/, "")
      |> String.replace(~r/```\s*$/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, "Failed to parse JSON: #{inspect(error)}"}
    end
  end
end
