defmodule CaptainFactWeb.UserSocket do
  use Phoenix.Socket

  require Logger
  import Guardian.Phoenix.Socket
  alias CaptainFactWeb.{ErrorView, ChangesetView}
  alias CaptainFact.Accounts.UserPermissions
  alias CaptainFact.Authenticator.GuardianImpl

  ## Channels
  channel("video_debate:*", CaptainFactWeb.VideoDebateChannel)
  channel("video_debate_history:*", CaptainFactWeb.VideoDebateHistoryChannel)
  channel("statement_history:*", CaptainFactWeb.VideoDebateHistoryChannel)
  channel("statements:video:*", CaptainFactWeb.StatementsChannel)
  channel("comments:video:*", CaptainFactWeb.CommentsChannel)

  ## Transports
  transport(:websocket, Phoenix.Transports.WebSocket)

  # Connect with token
  def connect(%{"token" => token}, socket) do
    case authenticate(socket, GuardianImpl, token) do
      {:ok, authed_socket} ->
        user_id =
          case Guardian.Phoenix.Socket.current_resource(authed_socket) do
            nil -> nil
            user -> user.id
          end

        {:ok, assign(authed_socket, :user_id, user_id)}

      _ ->
        # Fallback on default socket
        {:ok, assign(socket, :user_id, nil)}
    end
  end

  # Public connect
  def connect(_, socket) do
    {:ok, assign(socket, :user_id, nil)}
  end

  def multi_assign(socket, assigns_list) do
    Enum.reduce(assigns_list, socket, fn {key, value}, socket ->
      assign(socket, key, value)
    end)
  end

  def handle_in_authenticated(command, params, socket, handler) do
    case socket.assigns.user_id do
      nil -> {:reply, :error, socket}
      _ -> rescue_handler(handler, command, params, socket)
    end
  end

  def rescue_handler(handler, command, params, socket) do
    try do
      handler.(command, params, socket)
    rescue
      e in UserPermissions.PermissionsError ->
        reply_error(socket, Phoenix.View.render(ErrorView, "403.json", %{reason: e}))

      e in Ecto.InvalidChangesetError ->
        reply_error(socket, ChangesetView.render("error.json", %{changeset: e.changeset}))

      _ in Ecto.NoResultsError ->
        reply_error(socket, Phoenix.View.render(ErrorView, "404.json", []))

      e ->
        Logger.error("[RescueChannel] An unknown error just popped : #{inspect(e)}")

        Logger.debug(fn ->
          "Stacktrace: #{inspect(System.stacktrace(), pretty: true)}"
        end)

        reply_error(socket, Phoenix.View.render(ErrorView, "error.json", []))
    catch
      e ->
        Logger.error("[RescueChannel] Uncatched exception : #{inspect(e)}")
        reply_error(socket, Phoenix.View.render(ErrorView, "error.json", []))
    end
  end

  def id(_socket), do: nil

  defp reply_error(socket, error) do
    {:reply, {:error, error}, socket}
  end
end
