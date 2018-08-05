defmodule CaptainFact.Authenticator.GuardianImpl do
  use Guardian, otp_app: :captain_fact

  alias DB.Repo
  alias DB.Schema.User
  alias Kaur.Result

  @aud "captain_fact_#{Mix.env()}"

  def subject_for_token(%User{id: id}, _claims) do
    Result.ok("User:#{id}")
  end

  def subject_for_token(_, _) do
    Result.error("token is based on a user")
  end

  def resource_from_claims(claims) do
    "User:" <> user_id = claims["sub"]

    User
    |> Repo.get(user_id)
    |> Result.from_value()
    |> Result.map_error(fn :no_value -> :user_not_found end)
  end

  # ---- Guardian.DB boilerplate ----

  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    Guardian.DB.on_verify(claims, token)
    |> Result.and_then(fn {claims, _token} ->
      case claims do
        %{"aud" => @aud} -> Result.ok(claims)
        _ -> Result.error(:wrong_audience_in_jwt)
      end
    end)
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end

  def build_claims(claims, _resource, _opts) do
    claims
    |> Map.put("aud", @aud)
    |> Result.ok()
  end

  defmodule Pipeline do
    use Guardian.Plug.Pipeline,
      otp_app: :captain_fact,
      module: CaptainFact.Authenticator.GuardianImpl,
      error_handler: CaptainFact.Authenticator.GuardianImpl.ErrorHandler
  end

  defmodule ErrorHandler do
    import Plug.Conn

    def auth_error(conn, {_type, _reason}, _opts) do
      %{error: "unauthorized"}
      |> Poison.encode()
      |> Result.and_then(fn body ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, body)
      end)
    end
  end
end
