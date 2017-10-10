defmodule CaptainFact.Email do
  import Bamboo.Email
  require CaptainFact.Actions.Analysers.Reputation

  alias CaptainFact.Repo
  alias CaptainFact.Accounts.{ResetPasswordRequest, InvitationRequest, User}
  alias CaptainFact.Actions.Analysers.Reputation

  # TODO GetText i18n

  @cf_no_reply "no-reply@captainfact.io"
  @confirm_email_reputation elem(Reputation.action_reputation_change(:email_confirmed), 0)


  # Welcome + verify email

  def welcome_email(user) do
    new_email(from: @cf_no_reply)
    |> to(user)
    |> subject("Welcome to CaptainFact.io !")
    |> html_body("""
       We're glad having you joining us on CaptainFact ! To confirm your email and gain a bonus of
       +#{@confirm_email_reputation} reputation right now, click on this link :
       <a href="#{frontend_url()}/confirm_email/#{user.email_confirmation_token}">
         Confirm email
       </a>
       <br/><br/>
       If you need help or want to know more about how it works, check
       <a href="#{frontend_url()}/help">the help pages</a>.
       """)
  end

  # Reset password

  def reset_password_request_mail(req = %ResetPasswordRequest{user: %Ecto.Association.NotLoaded{}}),
    do: reset_password_request_mail(Repo.preload(req, :user))
  def reset_password_request_mail(%ResetPasswordRequest{user: user, token: token, source_ip: ip}) do
    new_email(from: @cf_no_reply)
    |> to(user)
    |> subject("CaptainFact.io - Reset your password")
    |> html_body("""
       You recently asked to reset your password on https://captainfact.io. Click on the link below to do so :
       <a href="#{frontend_url()}/reset_password/confirm/#{token}">Reset pasword</a>
       <br/>
       Please ignore this email if the request is not comming from you.
       <br/><br/>
       Reset requested by ip : #{ip}
       """)
  end

  # Invitation

  def invite_user_email(req = %InvitationRequest{invited_by: %Ecto.Association.NotLoaded{}}),
    do: invite_user_email(Repo.preload(req, :invited_by))
  def invite_user_email(%InvitationRequest{invited_by: invited_by, email: email, token: token}) do
    new_email(from: @cf_no_reply)
    |> to(email)
    |> subject(invitation_subject(invited_by))
    |> html_body("""
       Please follow this link to create your account :
       <a href="#{frontend_url()}/signup?invitation_token=#{token}">Create account</a>
       """)
  end

  defp frontend_url, do: Application.fetch_env!(:captain_fact, :frontend_url)

  defp invitation_subject(nil),
    do: "Your invitation to try CaptainFact.io is ready !"
  defp invitation_subject(user = %User{}),
    do: "#{User.user_appelation(user)} invited you to try CaptainFact.io !"
end