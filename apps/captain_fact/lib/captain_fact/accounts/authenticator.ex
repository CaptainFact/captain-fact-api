defmodule CaptainFact.Accounts.Authenticator do
  @moduledoc"""
  Handle all authentication intelligence. Must be generic and avoid all references to
  Ueberauth.
  """

  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.User
  alias CaptainFact.Accounts


  # ---- Identity ----

  def validate_pass(_encrypted, password) when password in [nil, ""],
    do: {:error, "password_required"}
  def validate_pass(encrypted, password) do
    if Comeonin.Bcrypt.checkpw(password, encrypted) do
      :ok
    else
      {:error, "invalid_password"}
    end
  end

  # ---- Third party authentication ----

  @doc"""
  get_user_by_provider provider, provider_id, email
  Get a user by its provider infos.

  As email returned by Facebook is [always verified](https://stackoverflow.com/questions/14280535/is-it-possible-to-check-if-an-email-is-confirmed-on-facebook)
  we can trust it and directly link to an existing user if there's one

  Return user or nil if no account exist for this email or fb_user_id
  """
  def get_user_by_third_party(_, _, nil), do: nil
  def get_user_by_third_party(:facebook, fb_user_id, email) do
    User
    |> where([u], u.fb_user_id == ^fb_user_id)
    |> or_where([u], u.email == ^email)
    |> Repo.all()
    |> Enum.reduce(nil, fn (user, best_fit) ->
         # User may link a facebook account, change its facebook email and re-connect with facebook
         # so we link by default using the facebook account and if none we try to link with email
         if user.fb_user_id == fb_user_id or is_nil(best_fit),
           do: user, else: best_fit
       end)
  end

  def link_provider!(user, provider_infos = %{picture_url: picture_url}) do
    {:ok, updated_user} =
      user
      |> User.provider_changeset(provider_infos)
      |> Repo.update!()
      |> Accounts.unlock_achievement(:social_networks)

    Accounts.confirm_email!(updated_user)
    case Accounts.fetch_picture(updated_user, picture_url) do
      {:ok, final_user} -> final_user
      _ -> updated_user # Don't fail if we didn't get the picture
    end
  end

  def unlink_provider!(user, :facebook) do
    # TODO Send a request to facebook to unlink on their side too
    user
    |> User.provider_changeset(%{fb_user_id: nil})
    |> Repo.update!()
  end
end