defmodule CaptainFactWeb.CollectiveModerationController do
  use CaptainFactWeb, :controller
  alias CaptainFact.Videos.VideoHashId
  alias CaptainFact.Moderation
  alias CaptainFactWeb.UserActionView

  action_fallback CaptainFactWeb.FallbackController
  # TODO Auth

  @nb_random_actions 5

  def random(conn, _params) do
    # TODO check permissions
    actions = Moderation.random(@nb_random_actions)
    render(conn, UserActionView, :index, users_actions: actions)
  end

  def video(conn, %{"id" => video_hash_id}) do
    # TODO check permissions
    actions = Moderation.video(VideoHashId.decode!(video_hash_id))
    render(conn, UserActionView, :index, users_actions: actions)
  end
end
