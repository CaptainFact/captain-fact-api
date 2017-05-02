defmodule CaptainFact.VideoDebateActionsChannel do
  use CaptainFact.Web, :channel

  alias Phoenix.View
  alias CaptainFact.{ VideoDebateAction, VideoHashId, VideoDebateActionView }

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
end
