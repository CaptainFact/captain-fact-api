defmodule CaptainFact.Authenticator.GuardianImpl do
  use Guardian, otp_app: :captain_fact

  alias DB.Repo
  alias DB.Schema.User
  alias Kaur.Result

  def subject_for_token(%User{id: id}, _claims) do
    Result.ok("User:#{id}")
  end

  def subject_for_token(_,_) do
    Result.error("token is based on a user")
  end

  def resource_from_claims(claims) do
    "User:" <> user_id = claims["sub"]

    %User{}
    |> Repo.get(user_id)
    |> Result.from_value()
    |> Result.map_error(fn :no_value -> :user_not_found end)
  end

end
