defimpl ExAdmin.Authentication, for: Plug.Conn do
  alias CaptainFact.Router.Helpers
  alias CaptainFact.Authentication, as: Auth

  def use_authentication?(_), do: true
  def current_user(conn), do: Guardian.Plug.current_resource(conn)
  def current_user_name(conn), do: Guardian.Plug.current_resource(conn).name

  def session_path(conn, :destroy), do: "/api/auth/signout"
  def session_path(conn, _), do: ""
end

defmodule CaptainFact.Plugs.SuperAdmin do
  import Plug.Conn
  alias CaptainFact.User

  def init(default), do: default

  def call(conn, _default) do
    check_user(conn, Guardian.Plug.current_resource(conn))
  end

  defp check_user(conn, %User{id: 1}), do: conn

  defp check_user(conn, _) do
    conn
    |> Plug.Conn.halt()
    |> Plug.Conn.send_resp(401, "Unhautorized")
  end
end
