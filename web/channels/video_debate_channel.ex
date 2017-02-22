defmodule CaptainFact.VideoDebateChannel do
  use CaptainFact.Web, :channel

  alias CaptainFact.Statement
  alias CaptainFact.StatementView
  alias CaptainFact.Video
  alias CaptainFact.VideoView
  alias CaptainFact.Speaker
  alias CaptainFact.SpeakerView
  alias CaptainFact.VideoSpeaker

  def join("video_debate:" <> video_id_str, payload, socket) do
    video_id = String.to_integer(video_id_str)
    if authorized?(payload) do
      video_with_statements =
        Video
        |> Video.with_speakers()
        |> Video.with_statements()
        |> Repo.get!(video_id)
        |> Phoenix.View.render_one(CaptainFact.VideoView, "video_with_statements.json")
      IO.inspect(video_with_statements)
      {:ok, video_with_statements, assign(socket, :video_id, video_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Add a new statement
  """
  def handle_in("new_statement", params, socket) do
    # TODO Verify user is owner / admin
    changeset = Statement.changeset(
      %Statement{
        video_id: socket.assigns.video_id,
        status: :voting
      }, params
    )
    case Repo.insert(changeset) do
      {:ok, statement} ->
        socket |>
          broadcast!("new_statement", StatementView.render("show.json", statement: statement))
        {:reply, :ok, socket}
      {:error, _reason} ->
        {:reply, :error, socket}
    end
  end

  @doc """
  Add an existing speaker to the video
  """
  def handle_in("new_speaker", %{"id" => id}, socket) do
    # TODO link existing speaker
  end

  @doc """
  Add a new speaker to the video
  """
  def handle_in("new_speaker", %{"full_name" => full_name}, socket) do
    speaker_changeset = Speaker.changeset(%Speaker{full_name: full_name})

    case Repo.insert(speaker_changeset) do
      {:ok, speaker} ->
        # Insert association between video and speaker
        %VideoSpeaker{speaker_id: speaker.id, video_id: socket.assigns.video_id}
        |> VideoSpeaker.changeset()
        |> Repo.insert!()

        # Broadcast the speaker
        rendered_speaker = SpeakerView.render("show.json", speaker: speaker)
        broadcast!(socket, "new_speaker", rendered_speaker)
        {:reply, :ok, socket}
      {:error, _reason} ->
        {:reply, :error, socket}
    end
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    # TODO Verify video exists and user is allowed for it (is_private)
    true
  end
end
