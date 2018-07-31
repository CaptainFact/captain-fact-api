defmodule CaptainFact.Authenticator.OAuthTest do
  use CaptainFact.DataCase

  alias DB.Schema.User
  alias CaptainFact.Accounts.Invitations
  alias CaptainFact.Authenticator.OAuth
  alias CaptainFact.Authenticator.ProviderInfos

  describe "Facebook" do
    test "login with existing user using FB id" do
      user = insert(:user)
      # Set nil email on provider infos to ensure we're finding him by ID
      provider_infos = fb_provider_infos_from_user(user, %{email: nil})
      result = OAuth.find_or_create_user!(provider_infos)
      assert result.id == user.id
    end

    test "login with existing user using email" do
      user = insert(:user, fb_user_id: nil)
      provider_infos = fb_provider_infos_from_user(user, %{uid: "4242"})
      result = OAuth.find_or_create_user!(provider_infos)
      assert result.id == user.id
      # Assert profile gets linked
      assert result.fb_user_id == "4242"
    end

    test "create account if it doesn't exist" do
      user = build(:user)
      provider_infos = fb_provider_infos_from_user(user)

      result = OAuth.find_or_create_user!(provider_infos)
      refute is_nil(result.id)
      assert result.email == user.email
      assert result.fb_user_id == user.fb_user_id
    end

    test "create account fails if invitation system is enabled and bad invitation token" do
      # Enable invitation system just for this test
      Invitations.enable()
      on_exit(fn -> Invitations.disable() end)

      # Mock user
      user = build(:user)
      provider_infos = fb_provider_infos_from_user(user)

      # Fail if no invitation token or invalid
      assert OAuth.find_or_create_user!(provider_infos) == {:error, "invalid_invitation_token"}

      assert OAuth.find_or_create_user!(provider_infos, "BullshitInvitationToken") ==
               {:error, "invalid_invitation_token"}
    end

    test "return a proper error when trying to create account without email permission" do
      user = build(:user)
      provider_infos = fb_provider_infos_from_user(user, %{email: nil})
      invitation_token = insert(:invitation_request).token
      result = OAuth.find_or_create_user!(provider_infos, invitation_token)
      assert result == {:error, "invalid_email"}
    end

    test "if user changed its email and has 2 accounts, always prefer facebook auth account" do
      nb_accounts_before = Repo.aggregate(User, :count, :id)
      nb_to_create = 10
      # User creates 5 accounts via email
      user_emails = insert_list(div(nb_to_create, 2), :user, %{fb_user_id: nil})
      # User create an account using facebook with a new, unused email
      user_facebook = insert(:user)
      # And create again 4 accounts via email
      user_emails =
        user_emails ++ insert_list(div(nb_to_create, 2) - 1, :user, %{fb_user_id: nil})

      # User changes its email on FB using existing emails and try to login...
      for user <- user_emails do
        provider_infos =
          fb_provider_infos_from_user(user, %{
            uid: user_facebook.fb_user_id,
            email: user.email
          })

        result = OAuth.find_existing_user(provider_infos)
        assert result.id == user_facebook.id
        assert Repo.aggregate(User, :count, :id) == nb_accounts_before + nb_to_create
      end
    end
  end

  defp fb_provider_infos_from_user(user, opt_params \\ %{}) do
    Map.merge(
      %ProviderInfos{
        provider: :facebook,
        uid: user.fb_user_id,
        email: user.email
      },
      opt_params
    )
  end
end
