defmodule CF.LLMs.StatementsCreator do
  @moduledoc """
  Functions to create statements from a video that has captions using LLMs
  """

  import Ecto.Query
  require EEx
  require Logger

  @max_caption_length 1000

  @model_lama_3_small %{
    name: "llama-3-sonar-small-32k-chat",
    parameter_count: "8B",
    context_length: 32768
  }

  @model_lama_3_large %{
    name: "llama-3-sonar-large-32k-chat",
    parameter_count: "70B",
    context_length: 32768
  }

  @model_mistral_7b %{
    name: "mistral-7b-instruct",
    parameter_count: "8x7B",
    context_length: 16384
  }

  # Load prompt messages templates
  EEx.function_from_file(
    :defp,
    :generate_system_prompt,
    Path.join(__DIR__, "templates/statements_extractor_system_prompt.eex")
  )

  EEx.function_from_file(
    :defp,
    :generate_user_prompt,
    Path.join(__DIR__, "templates/statements_extractor_user_prompt.eex"),
    [
      :video,
      :captions
    ]
  )

  @doc """
  Create statements from a video that has captions using LLMs
  """
  def process_video!(video_id) do
    DB.Schema.Video
    |> join(:inner, [v], vc in DB.Schema.VideoCaption, on: v.id == vc.video_id)
    |> where([v, vc], v.id == ^video_id)
    |> order_by([v, vc], desc: vc.inserted_at)
    |> limit(1)
    |> select([v, vc], {v, vc})
    |> DB.Repo.one()
    |> case do
      nil ->
        raise "Video or captions not found"

      {video, video_caption} ->
        video_caption.parsed
        |> chunk_captions()
        |> Enum.map(fn captions ->
          video
          |> get_llm_suggested_statements(captions)
          |> filter_known_statements(video)
          |> create_statements_from_inputs(video)
          |> broadcast_statements(video)

          Process.sleep(500)
        end)
    end
  end

  @doc """
  Chunk captions everytime we reach the max caption length
  """
  defp chunk_captions(captions) do
    # TODO: Base on strings lengths + @max_caption_length
    Enum.chunk_every(captions, 50)
  end

  defp get_llm_suggested_statements(video, captions, retries \\ 0) do
    api_key = Application.get_env(:cf, :openai_api_key)
    api_url = Application.get_env(:cf, :openai_api_url)

    unless api_key && api_url do
      raise "OpenAI API configuration missing"
    end

    try do
      headers = [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"},
        {"Accept", "application/json"}
      ]

      system_prompt = generate_system_prompt()
      user_prompt = generate_user_prompt(video, captions)

      body =
        %{
          "model" => @model_lama_3_large[:name],
          "max_tokens" =>
            @model_lama_3_large[:context_length] -
              String.length(system_prompt) - String.length(user_prompt) - 500,
          "stream" => false,
          "messages" => [
            %{
              "role" => "system",
              "content" => system_prompt
            },
            %{
              "role" => "user",
              "content" => user_prompt
            }
          ]
        }
        |> Jason.encode!()

      case HTTPoison.post("#{api_url}/chat/completions", body, headers,
             timeout: 30_000,
             recv_timeout: 30_000
           ) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          body
          |> Jason.decode!()
          |> Map.get("choices")
          |> List.first()
          |> get_in(["message", "content"])
          |> get_json_str_from_content!()
          |> Jason.decode!()
          |> Map.get("statements")
          |> check_statements_input_format!()

        {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
          raise "Network error: #{status_code} - #{inspect(body)}"

        {:error, %HTTPoison.Error{reason: reason}} ->
          raise inspect(reason)
      end
    rescue
      error ->
        if retries > 0 do
          Logger.warn("Failed to get LLM suggested statements: #{inspect(error)}. Retrying...")
          Process.sleep(1000)
          get_llm_suggested_statements(video, captions, retries - 1)
        else
          Logger.error(inspect(error))
          reraise error, __STACKTRACE__
        end
    end
  end

  defp check_statements_input_format!(statements_inputs) do
    for %{"text" => text, "time" => time} <- statements_inputs do
      unless is_binary(text) and is_integer(time) do
        raise "Invalid statement input format"
      end
    end

    statements_inputs
  end

  # Remove statements when we already have a similar one at time/text
  defp filter_known_statements(statements, video) do
    existing_statements =
      DB.Schema.Statement
      |> where([s], s.video_id == ^video.id)
      |> DB.Repo.all()

    Enum.reject(statements, fn %{"text" => text, "time" => time} ->
      Enum.any?(existing_statements, fn s ->
        s.time >= time - 5 and s.time <= time + 5 and String.jaro_distance(s.text, text) > 0.80
      end)
    end)
  end

  defp create_statements_from_inputs(statements_inputs, video) do
    inserted_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    {nb_statements, statements} =
      DB.Repo.insert_all(
        DB.Schema.Statement,
        Enum.map(statements_inputs, fn %{"text" => text, "time" => time} ->
          %{
            video_id: video.id,
            text: text,
            time: time,
            inserted_at: inserted_at,
            updated_at: inserted_at
          }
        end),
        returning: true
      )

    statements
  end

  defp broadcast_statements(statements, video) do
    statements
    |> Enum.map(fn statement ->
      CF.RestApi.Endpoint.broadcast(
        "statements:video:#{DB.Type.VideoHashId.encode(video.id)}",
        "statement_added",
        CF.RestApi.StatementView.render("show.json", statement: statement)
      )
    end)
  end

  # JSON content can optionally be wrapped in a ```json ... ``` block
  defp get_json_str_from_content!(content) do
    case Regex.scan(~r/```json\n(.+)\n```/mis, content) do
      [[_, json_str]] -> json_str
      _ -> content
    end
  end
end
