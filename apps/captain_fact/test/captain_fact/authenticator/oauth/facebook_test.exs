defmodule CaptainFact.Authenticator.OAuth.FacebookTest do
  import DB.Factory
  use CaptainFact.DataCase
  import Mock
  alias CaptainFact.Authenticator.OAuth.Facebook

  doctest Facebook

  # TODO add arity
  describe "revoke_permissions/1" do
    test "sends an HTTP DELETE request to facebook" do
      user =
        :user
        |> build
        |> with_fb_user_id
        |> insert

      facebook_user_perms_url = "/#{user.fb_user_id}/permissions"

      # defining Mock for OAuth2 Client module
      with_mock OAuth2.Client,
                # Unmocked functions will be pass to original module
                [:passthrough],
                # mock delete function
                delete: fn _client, url when facebook_user_perms_url == url ->
                  {:ok, %OAuth2.Response{status_code: 200, body: %{data: "success"}}}
                end do
        Facebook.revoke_permissions(user)

        # Check that the call was made as we expected
        assert called(OAuth2.Client.delete(:_, facebook_user_perms_url))
      end
    end
  end
end
