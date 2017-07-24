defmodule CaptainFact.Web.UserSocket do
  use Phoenix.Socket

  require Logger
  import Guardian.Phoenix.Socket
  alias CaptainFact.Web.ErrorView

  ## Channels
  channel "video_debate:*", CaptainFact.Web.VideoDebateChannel
  channel "video_debate_history:*", CaptainFact.Web.VideoDebateHistoryChannel
  channel "statements_history:*", CaptainFact.Web.VideoDebateHistoryChannel
  channel "statements:video:*", CaptainFact.Web.StatementsChannel
  channel "comments:video:*", CaptainFact.Web.CommentsChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket

  def connect(%{"token" => token}, socket) do
    case sign_in(socket, token) do
      {:ok, authed_socket, _guardian_params} ->
        user_id = case Guardian.Phoenix.Socket.current_resource(authed_socket) do
          nil -> nil
          user -> user.id
        end
        {:ok, assign(authed_socket, :user_id, user_id)}
      _ ->
        {:ok, assign(socket, :user_id, nil)}
    end
  end

  def rescue_channel_errors(handler) when is_function(handler) do
    fn command, params, socket ->
      try do
        handler.(command, params, socket)
      rescue
        e in CaptainFact.UserPermissions.PermissionsError ->
          reply_error(socket, Phoenix.View.render(ErrorView, "403.json", %{reason: e}))
        _ in Ecto.NoResultsError ->
          reply_error(socket, Phoenix.View.render(ErrorView, "404.json", []))
        e ->
          Logger.error("[RescueChannel] An unknown error just popped : #{inspect(e)}")
          reply_error(socket, Phoenix.View.render(ErrorView, "error.json", []))
      end
    end
  end

  def id(_socket), do: nil

  defp reply_error(socket, error) do
    {:reply, {:error, error}, socket}
  end
end
