defmodule CaptainFactWeb.CollectiveModerationController do
  use CaptainFactWeb, :controller
  alias CaptainFact.Videos.VideoHashId
  alias CaptainFact.Moderation
  alias CaptainFactWeb.UserActionView

  action_fallback CaptainFactWeb.FallbackController

  # All methods here require authentication
  plug Guardian.Plug.EnsureAuthenticated, handler: CaptainFactWeb.AuthController

  @nb_random_actions 5

  def random(conn, _params) do
    actions = Moderation.random(Guardian.Plug.current_resource(conn), @nb_random_actions)
    render(conn, UserActionView, :index, users_actions: actions)
  end

  def video(conn, %{"id" => video_hash_id}) do
    actions = Moderation.video(Guardian.Plug.current_resource(conn), VideoHashId.decode!(video_hash_id))
    render(conn, UserActionView, :index, users_actions: actions)
  end

  def post_feedback(conn, %{"action_id" => action_id, "value" => value}) when is_integer(value) do
    user = Guardian.Plug.current_resource(conn)
    Moderation.feedback!(user, action_id, value)
    send_resp(conn, 204, "")
  end
end
