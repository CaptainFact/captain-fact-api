defmodule CF.RestApi.ModerationController do
  use CF.RestApi, :controller

  alias CF.Moderation
  alias CF.RestApi.ModerationEntryView

  action_fallback(CF.RestApi.FallbackController)

  # All methods here require authentication
  plug(Guardian.Plug.EnsureAuthenticated, handler: CF.RestApi.AuthController)

  def random(conn, _) do
    case Moderation.random!(Guardian.Plug.current_resource(conn)) do
      nil ->
        send_resp(conn, 204, "")

      entry ->
        render(conn, ModerationEntryView, :show, moderation_entry: entry)
    end
  end

  def post_feedback(conn, %{"action_id" => id, "value" => value, "reason" => reason})
      when is_integer(id) and is_integer(value) and is_integer(reason) do
    user = Guardian.Plug.current_resource(conn)
    Moderation.feedback!(user, id, value, reason)
    send_resp(conn, 204, "")
  end
end
