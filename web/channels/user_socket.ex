defmodule CaptainFact.UserSocket do
  use Phoenix.Socket
  import Guardian.Phoenix.Socket

  ## Channels
  channel "video_debate:*", CaptainFact.VideoDebateChannel
  channel "video_debate_actions:*", CaptainFact.VideoDebateActionsChannel
  channel "statements:video:*", CaptainFact.StatementsChannel
  channel "comments:video:*", CaptainFact.CommentsChannel

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

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     CaptainFact.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
