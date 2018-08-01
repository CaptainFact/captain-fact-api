defmodule CaptainFact.Invitations.InvitationsTest do
  use CaptainFact.DataCase
  use Bamboo.Test

  alias DB.Schema.InvitationRequest
  alias CaptainFact.Accounts.Invitations

  describe "with system enabled" do
    setup do
      Invitations.enable()
      on_exit(fn -> Invitations.disable() end)
    end

    test "invitation request get created with given invited_by user" do
      email = "test@email.com"
      user = insert(:user)
      {:ok, req} = Invitations.request_invitation(email, user)
      assert is_nil(req.token), "don't generate token before necessary"
      assert user.id == req.invited_by_id
      assert email == req.email
    end

    test "send a mail when calling send_invite/1" do
      req = insert(:invitation_request)
      Invitations.send_invite(req)
      assert_delivered_email(CaptainFactMailer.Email.invitation_to_register(req))
    end

    test "send mails when calling send_invites/1" do
      Repo.delete_all(InvitationRequest)
      nb_invites = 10
      requests = insert_list(nb_invites, :invitation_request)
      Invitations.send_invites(nb_invites)

      Enum.each(requests, fn req ->
        assert_delivered_email(CaptainFactMailer.Email.invitation_to_register(req))
      end)
    end

    test "multiple requests only insert one time but doesn't crash" do
      email = "test@email.com"
      user = insert(:user)
      {:ok, req} = Invitations.request_invitation(email)
      {:ok, req2} = Invitations.request_invitation(email)
      {:ok, req3} = Invitations.request_invitation(email, user)

      assert req.id == req2.id
      assert req2.id == req3.id
    end

    test "cannot insert with bad email" do
      assert {:error, "invalid_email"} == Invitations.request_invitation("toto@yopmail.fr")
      assert {:error, "invalid_email"} == Invitations.request_invitation("toto@")
      assert {:error, "invalid_email"} == Invitations.request_invitation("xxxxxxxxx")
    end

    test "re-asking for an invitation reset invitation_sent boolean to false" do
      req = insert(:invitation_request, %{invitation_sent: true})
      {:ok, req_updated} = Invitations.request_invitation(req.email)
      assert req_updated.invitation_sent == false
    end

    # TODO What if user already have an account and request an invitation ?
  end

  describe "with system disabled (default)" do
    test "valid? always returns true" do
      assert Invitations.valid_invitation?("xxxxxxxxBAD_INVITxxxxxxxxxxxx") == true
    end

    test "still consumes invitation" do
      invitation = insert(:invitation_request)
      Invitations.consume_invitation(invitation)
      assert DB.Repo.get(InvitationRequest, invitation.id) == nil
    end
  end
end
