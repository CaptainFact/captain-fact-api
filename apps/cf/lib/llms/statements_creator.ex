defmodule CF.LLMs.StatementsCreator do
  @moduledoc """
  Functions to create statements from a video that has captions using LLMs
  """

  import Ecto.Query
  require EEx
  require Logger

  @captions_chunk_size 300

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
    video = DB.Repo.get(DB.Schema.Video, video_id)
    video_caption = fetch_or_download_captions(video)

    if video_caption != nil do
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

  defp fetch_or_download_captions(video) do
    case DB.Schema.VideoCaption
         |> where([vc], vc.video_id == ^video.id)
         |> order_by(desc: :inserted_at)
         |> limit(1)
         |> DB.Repo.one() do
      nil ->
        case CF.Videos.download_captions(video) do
          {:ok, video_caption} -> video_caption
          _ -> nil
        end

      video_caption ->
        video_caption
    end
  end

  # Chunk captions each time we reach the max caption length
  defp chunk_captions(captions) do
    # TODO: Add last captions from previous batch to preserve context
    Enum.chunk_every(captions, @captions_chunk_size)
  end

  defp get_llm_suggested_statements(video, captions, retries \\ 5) do
    OpenAI.chat_completion(
      model: Application.get_env(:cf, :openai_model),
      response_format: %{type: "json_object"},
      stream: false,
      messages: [
        %{
          role: "system",
          content: generate_system_prompt()
        },
        %{
          role: "user",
          content: generate_user_prompt(video, captions)
        }
      ]
    )
    |> case do
      {:ok, %{choices: choices}} ->
        choices
        |> List.first()
        |> get_in(["message", "content"])
        |> get_json_str_from_content!()
        |> Jason.decode!()
        |> Map.get("statements")
        |> check_statements_input_format!()

      {:error, error} ->
        if retries > 0 do
          Logger.warn("Failed to get LLM suggested statements: #{inspect(error)}. Retrying...")
          Process.sleep(1000)
          get_llm_suggested_statements(video, captions, retries - 1)
        else
          Logger.error(inspect(error))
          raise error
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
            text: CF.Utils.truncate(text, 280),
            time: time,
            inserted_at: inserted_at,
            updated_at: inserted_at,
            is_draft: true
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
