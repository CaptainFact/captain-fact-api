defmodule CaptainFact.VideoDebateActionsChannel do
  use CaptainFact.Web, :channel

  alias Phoenix.View
  alias Ecto.Multi
  alias CaptainFact.{ VideoDebateAction, VideoHashId, Statement }
  alias CaptainFact.{ VideoDebateActionView, StatementView }

  import CaptainFact.VideoDebateActionCreator, only: [action_restore: 3]


  def join("video_debate_actions:" <> video_id_hash, _payload, socket) do
    video_id = VideoHashId.decode!(video_id_hash)
    rendered_actions =
      VideoDebateAction
      |> VideoDebateAction.with_user
      |> where([a], a.video_id == ^video_id)
      |> Repo.all()
      |> View.render_many(VideoDebateActionView, "action.json")
    {:ok, %{actions: rendered_actions}, assign(socket, :video_id, video_id)}
  end

  def handle_in(command, params, socket) do
    case socket.assigns.user_id do
      nil -> {:reply, :error, socket}
      _ -> handle_in_authenticated(command, params, socket)
    end
  end

  def handle_in_authenticated("restore_statement", %{"id" => id}, socket) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    statement = Repo.get_by!(Statement, id: id, is_deleted: true)
    Multi.new
    |> Multi.update(:statement, Statement.changeset_restore(statement))
    |> Multi.run(:action_restore, fn %{statement: statement} ->
      Repo.insert(action_restore(user_id, video_id, statement))
     end)
    |> Repo.transaction()
    |> case do
        {:ok, %{action_restore: action, statement: statement}} ->
          # Broadcast action
          rendered_action =
            action
            |> Map.put(:user, Repo.one!(Ecto.assoc(action, :user)))
            |> View.render_one(VideoDebateActionView, "action.json")
          broadcast!(socket, "new_action", rendered_action)

          # Broadcast statement
          CaptainFact.Endpoint.broadcast(
            "statements:video:#{VideoHashId.encode(video_id)}",
            "statement_added",
            StatementView.render("show.json", statement: statement)
          )
          {:reply, :ok, socket}
        {:error, _, reason, _} ->
          IO.inspect(reason)
          {:reply, :error, socket}
    end
  end
end
