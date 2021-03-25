defmodule CF.RestApi.VideoDebateHistoryChannel do
  @moduledoc """
  A channel to get modifications of the VideoDebate history (action log) in
  real time.
  """

  use CF.RestApi, :channel
  require Logger

  import CF.Actions.ActionCreator, only: [action_restore: 2, action_restore: 3]
  import CF.RestApi.UserSocket, only: [handle_in_authenticated: 4]

  alias Phoenix.View
  alias Ecto.Multi
  alias DB.Type.VideoHashId
  alias DB.Schema.Statement
  alias DB.Schema.Speaker
  alias DB.Schema.VideoSpeaker

  alias CF.Accounts.UserPermissions
  alias CF.VideoDebate.History
  alias CF.RestApi.{StatementView, SpeakerView, UserActionView}

  def join("video_debate_history:" <> video_hash_id, _payload, socket) do
    video_id = VideoHashId.decode!(video_hash_id)

    actions =
      video_id
      |> History.video_history()
      |> View.render_many(UserActionView, "user_action.json")

    {:ok, %{actions: actions}, assign(socket, :video_id, video_id)}
  end

  def join("statement_history:" <> statement_id, _payload, socket) do
    statement = Repo.get!(Statement, statement_id)

    actions =
      View.render_many(
        History.statement_history(statement_id),
        UserActionView,
        "user_action.json"
      )

    socket =
      socket
      |> assign(:statement_id, statement_id)
      |> assign(:video_id, statement.video_id)

    {:ok, %{actions: actions}, socket}
  end

  def handle_in(command, params, socket) do
    handle_in_authenticated(command, params, socket, &handle_in_authenticated!/3)
  end

  def handle_in_authenticated!("restore_statement", %{"id" => id}, socket) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    UserPermissions.check!(user_id, :restore, :statement)
    statement = Repo.get_by!(Statement, id: id, is_removed: true)

    Multi.new()
    |> Multi.update(:statement, Statement.changeset_restore(statement))
    |> Multi.insert(:action_restore, action_restore(user_id, statement))
    |> Repo.transaction()
    |> case do
      {:ok, %{action_restore: action, statement: statement}} ->
        # Broadcast action
        rendered_action =
          action
          |> Map.put(:user, Repo.one!(Ecto.assoc(action, :user)))
          |> View.render_one(UserActionView, "user_action.json")

        broadcast!(socket, "action_added", rendered_action)

        # Broadcast statement
        CF.RestApi.Endpoint.broadcast(
          "statements:video:#{VideoHashId.encode(video_id)}",
          "statement_added",
          StatementView.render("show.json", statement: statement)
        )

        CF.Algolia.StatementsIndex.save_object(statement)
        {:reply, :ok, socket}

      {:error, _, reason, _} ->
        Logger.debug(fn -> inspect(reason) end)
        {:reply, :error, socket}
    end
  end

  def handle_in_authenticated!("restore_speaker", %{"id" => id}, socket) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    UserPermissions.check!(user_id, :restore, :speaker)
    speaker = Repo.get(Speaker, id)

    video_speaker =
      VideoSpeaker.changeset(%VideoSpeaker{speaker_id: speaker.id, video_id: video_id})

    Multi.new()
    |> Multi.insert(:video_speaker, video_speaker)
    |> Multi.insert(:action_restore, action_restore(user_id, video_id, speaker))
    |> Repo.transaction()
    |> case do
      {:ok, %{action_restore: action}} ->
        # Broadcast the action
        rendered_action =
          action
          |> Map.put(:user, Repo.one!(Ecto.assoc(action, :user)))
          |> View.render_one(UserActionView, "user_action.json")

        broadcast!(socket, "action_added", rendered_action)
        # Broadcast the speaker
        CF.RestApi.Endpoint.broadcast(
          "video_debate:#{VideoHashId.encode(video_id)}",
          "speaker_added",
          SpeakerView.render("show.json", speaker: speaker)
        )

        CF.Algolia.VideosIndex.reindex_by_id(video_id)
        {:reply, :ok, socket}

      {:error, _reason} ->
        {:reply, :error, socket}
    end
  end
end
