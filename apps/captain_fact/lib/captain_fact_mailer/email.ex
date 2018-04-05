defmodule CaptainFactMailer.Email do
  @moduledoc"""
  Generate emails using templates in `templates` folder. All files must have two
  versions: `.html.eex` and `.text.eex`.

  Templates **must** have an english version (ex: `welcome.en.html.eex`).

  Ideally all templates should also be available in all languages
  specified by @supported_locales.
  """

  use Bamboo.Phoenix, view: CaptainFactMailer.View
  import CaptainFact.Gettext

  require CaptainFactJobs.Reputation

  alias DB.Repo
  alias DB.Schema.ResetPasswordRequest
  alias DB.Schema.InvitationRequest
  alias DB.Schema.User

  alias CaptainFactJobs.Reputation


  @sender_no_reply {"CaptainFact", "no-reply@captainfact.io"}
  @supported_locales ~w(fr en)


  def welcome_email(user) do
    user_email(user)
    |> subject(gettext_mail_user(user, "Welcome to CaptainFact.io !"))
    |> assign(:confirm_email_reputation, Reputation.self_reputation_change(:email_confirmed))
    |> render_localized(:welcome)
  end

  def newsletter(%{newsletter: false}, _, _), do: nil
  def newsletter(user, subject, html_message) do
    user_email(user)
    |> subject(subject)
    |> assign(:content, html_message)
    |> assign(:text_content, Floki.text(html_message))
    |> render_localized(:newsletter)
  end

  def reset_password_request_mail(req = %ResetPasswordRequest{user: %Ecto.Association.NotLoaded{}}),
    do: reset_password_request_mail(Repo.preload(req, :user))
  def reset_password_request_mail(%ResetPasswordRequest{user: user, token: token, source_ip: ip}) do
    user_email(user)
    |> subject(gettext_mail_user(user, "CaptainFact.io - Reset your password"))
    |> assign(:reset_password_token, token)
    |> assign(:source_ip, ip)
    |> render_localized(:reset_password)
  end

  def big_reputation_loss(user) do
    user_email(user)
    |> subject(gettext_mail_user(user, "About your recent loss of reputation on CaptainFact"))
    |> render_localized(:reputation_loss)
  end

  def invite_user_email(req = %InvitationRequest{invited_by: %Ecto.Association.NotLoaded{}}),
    do: invite_user_email(Repo.preload(req, :invited_by))
  def invite_user_email(%InvitationRequest{invited_by: invited_by, email: email, token: token}) do
    base_email()
    |> to(email)
    |> subject(invitation_subject(invited_by))
    |> assign(:invitation_token, token)
    |> render(:invitation) # No localisation (we don't know user's locale yet)
  end

  defp invitation_subject(nil),
    do: "Your invitation to try CaptainFact.io is ready !"
  defp invitation_subject(user = %User{}),
    do: gettext_mail_user(user, "%{name} invited you to try CaptainFact.io !", name: User.user_appelation(user))

  # Build a base email with `from` set and default layout
  defp base_email() do
    new_email(from: @sender_no_reply)
    |> put_html_layout({CaptainFactMailer.View, "_layout.html"})
    |> put_text_layout({CaptainFactMailer.View, "_layout.text"})
  end

  # Build a base email with user assigned to @user and `to` address set
  defp user_email(user) do
    base_email()
    |> to(user)
    |> assign(:user, user)
  end

  # If a user is available use his locale for rendering email. Otherwise just
  # render with default locale
  defp render_localized(email = %{assigns: %{user: %{locale: locale}}}, view)
  when locale in @supported_locales
  do
    Gettext.with_locale CaptainFact.Gettext, locale, fn ->
      try do
        render(email, String.to_atom(Atom.to_string(view) <> ".#{locale}"))
      rescue
        # Ideally templates should allways include all versions specified in
        # @supported_locales. But to avoid crashing if not the case, we render
        # the default english template if not found.
        _ in Phoenix.Template.UndefinedError ->
          render(email, String.to_atom(Atom.to_string(view) <> ".en"))
      end
    end
  end
  defp render_localized(email, view) do
    render(email, String.to_atom(Atom.to_string(view) <> ".en"))
  end
end