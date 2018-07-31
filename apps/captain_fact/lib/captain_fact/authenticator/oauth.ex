defmodule CaptainFact.Authenticator.OAuth do
  import Ecto.Query
  alias DB.Repo
  alias DB.Schema.User
  alias CaptainFact.Accounts
  alias CaptainFact.Authenticator.OAuth.Facebook
  alias CaptainFact.Authenticator.ProviderInfos

  @doc """
  Fetch user infos from third party
  """
  def fetch_user_from_third_party(:facebook, code) do
    client = Facebook.get_token!(code: code)

    with %{token: %{access_token: token}} when not is_nil(token) <- client,
         {:ok, provider_infos} <- Facebook.fetch_user(client) do
      provider_infos
    else
      %{token: %{access_token: nil}} -> {:error, "invalid_token"}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Return existing user if there's on for this email or FB account,
  create it otherwise.

  `invitation_token` is only required when creating the account.
  """
  def find_or_create_user!(infos = %ProviderInfos{}, invitation_token \\ nil) do
    case find_existing_user(infos) do
      nil ->
        # User doesn't exist, create it
        user_infos = provider_info_to_user_info(infos)

        with {:ok, user} <-
               Accounts.create_account(
                 user_infos,
                 invitation_token,
                 provider_params: Map.from_struct(infos),
                 allow_empty_username: true
               ) do
          link_provider!(user, infos)
        end

      user = %User{fb_user_id: nil} ->
        # A user for this account already exists, link its Facebook
        link_provider!(user, infos)

      user ->
        # User exist and its account is already linked, just return it
        user
    end
  end

  @doc """
  In case we have two accounts for this FB / email we match on FB first
  """
  def find_existing_user(%{provider: :facebook, uid: fb_user_id, email: email}) do
    User
    |> where([u], u.fb_user_id == ^fb_user_id)
    |> or_where([u], u.email == ^(email || ""))
    |> Repo.all()
    |> Enum.reduce(nil, fn user, best_fit ->
      if user.fb_user_id == fb_user_id or is_nil(best_fit),
        do: user,
        else: best_fit
    end)
  end

  @doc """
  Link profider specified in provider_infos to current user
  """
  def link_provider!(user, provider_infos) do
    # Link third party account to user
    {:ok, updated_user} =
      user
      |> User.provider_changeset(provider_info_to_user_info(provider_infos))
      |> Repo.update!()
      |> Accounts.unlock_achievement(:social_networks)

    # Email is always verified by third party, so it's save to confirm it
    Accounts.confirm_email!(updated_user)

    # Try to fetch picture
    picture_url = provider_infos.picture_url

    case picture_url && Accounts.fetch_picture(updated_user, picture_url) do
      {:ok, final_user} ->
        final_user

      # Don't fail if we didn't get the picture
      _ ->
        updated_user
    end
  end

  @doc """
  Unlink provider from given user account
  """
  def unlink_provider(user, :facebook) do
    # TODO Send a request to facebook to unlink on their side too
    user
    |> User.provider_changeset(%{fb_user_id: nil})
    |> Repo.update!()
  end

  # Converts provider infos to a struct ready to be given for User changesets
  defp provider_info_to_user_info(infos = %{provider: :facebook}) do
    %{
      fb_user_id: infos.uid,
      name: infos.name,
      email: infos.email,
      password: NotQwerty123.RandomPassword.gen_password()
    }
  end
end
