defmodule CaptainFact.VideoDebateActionChannel do
  use CaptainFact.Web, :channel

  alias CaptainFact.{ VideoDebateAction, VideoHashId }

  def join("video_debate_actions:" <> video_id_hash, _payload, socket) do
    video_id = VideoHashId.decode!(video_id_hash)
    query =
      from a in VideoDebateAction,
      where: a.video_id == ^video_id
    {:ok, Repo.all(query), assign(socket, :video_id, video_id)}
  end
end
