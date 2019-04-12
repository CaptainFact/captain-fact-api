defmodule CF.Mailer.EmailTest do
  use CF.DataCase
  alias CF.Mailer.Email

  @user_en build(:user, %{locale: "en"})
  @user_fr build(:user, %{locale: "fr"})

  # Public emails

  test "invitation is ready" do
    invit = build(:invitation_request, invited_by: nil)
    invit_frontend_url = "https://TEST_FRONTEND/signup?invitation_token=#{invit.token}"
    email = Email.invitation_to_register(invit)

    assert email.to == invit.email
    assert email.subject == "Your invitation to try CaptainFact.io is ready!"
    assert email.text_body =~ invit_frontend_url
    assert email.html_body =~ invit_frontend_url
  end

  test "invited by user" do
    invited_by = build(:user, name: "José Bové", username: "JB52")
    invit = build(:invitation_request, invited_by: invited_by)
    invit_frontend_url = "https://TEST_FRONTEND/signup?invitation_token=#{invit.token}"
    email = Email.invitation_to_register(invit)

    assert email.to == invit.email
    assert email.subject =~ invited_by.username
    assert email.subject =~ invited_by.name
    assert email.subject =~ "invited you to try CaptainFact.io!"
    assert email.text_body =~ invit_frontend_url
    assert email.html_body =~ invit_frontend_url
  end

  # User emails

  test "welcome email has basic fields and a link to confirm email" do
    email_en = Email.welcome(@user_en)
    email_fr = Email.welcome(@user_fr)

    common_welcome_test(@user_en, email_en)
    common_welcome_test(@user_fr, email_fr)

    assert email_en.subject == "Confirm your CaptainFact account"

    assert email_fr.subject ==
             "Confirmez votre compte CaptainFact pour obtenir +15pts de réputation 🌟️"
  end

  test "reputation loss" do
    email_en = Email.reputation_loss(@user_en)
    email_fr = Email.reputation_loss(@user_fr)

    assert email_en.to == @user_en
    assert email_en.subject == "About your recent loss of reputation on CaptainFact"
    assert email_en.text_body =~ "Your CaptainFact reputation passed below -5."
    assert email_en.html_body =~ "Your CaptainFact reputation passed below -5."

    assert email_fr.to == @user_fr
    assert email_fr.subject == "A propos de votre récente perte de réputation sur CaptainFact"

    assert email_fr.text_body =~
             "Votre réputation sur CaptainFact est récemment passée en dessous de -5"

    assert email_fr.html_body =~
             "Votre réputation sur CaptainFact est récemment passée en dessous de -5"
  end

  test "reset password" do
    request_en = DB.Factory.build(:reset_password_request, user: @user_en)
    request_fr = DB.Factory.build(:reset_password_request, user: @user_fr)

    email_en = Email.reset_password_request(request_en)
    email_fr = Email.reset_password_request(request_fr)

    common_reset_password_test(request_en, email_en)
    common_reset_password_test(request_fr, email_fr)

    assert email_en.subject == "CaptainFact.io - Reset your password"
    assert email_en.text_body =~ "You recently asked to reset your password on CF."
    assert email_en.html_body =~ "You recently asked to reset your password on CF."

    assert email_fr.subject == "CaptainFact.io - Réinitialisation du mot de passe"

    assert email_fr.text_body =~
             "Vous avez demandé la réinitialisation de votre mot de passe sur CF."

    assert email_fr.html_body =~
             "Vous avez demandé la réinitialisation de votre mot de passe sur CF."
  end

  test "newsletter" do
    html_content = """
    <h1>Hello World</h1>
    <p>This is an awesome test mail</p>
    """

    subject = "Hellowww"
    email_en = Email.newsletter(@user_en, subject, html_content)
    email_fr = Email.newsletter(@user_fr, subject, html_content)

    common_newsletter_test(@user_en, subject, html_content, email_en)
    common_newsletter_test(@user_fr, subject, html_content, email_fr)

    assert email_en.text_body =~ "Unsubscribe from this newsletter"
    assert email_fr.text_body =~ "Se désinscrire de cette newsletter"
    assert email_en.html_body =~ "Unsubscribe from this newsletter"
    assert email_fr.html_body =~ "Se désinscrire de cette newsletter"
  end

  defp common_newsletter_test(user, subject, html_content, email) do
    assert email.to == user
    assert email.subject == subject
    assert email.text_body =~ "Hello World"
    assert email.text_body =~ "This is an awesome test mail"
    assert email.html_body =~ html_content

    assert email.text_body =~
             "https://TEST_FRONTEND/newsletter/unsubscribe/#{user.newsletter_subscription_token}"

    assert email.html_body =~
             "https://TEST_FRONTEND/newsletter/unsubscribe/#{user.newsletter_subscription_token}"
  end

  defp common_welcome_test(user, email) do
    assert email.to == user

    assert email.html_body =~
             "https://TEST_FRONTEND/confirm_email/#{user.email_confirmation_token}"

    assert email.text_body =~
             "https://TEST_FRONTEND/confirm_email/#{user.email_confirmation_token}"
  end

  defp common_reset_password_test(request, email) do
    assert email.to == request.user
    assert email.text_body =~ request.source_ip
    assert email.text_body =~ "https://TEST_FRONTEND/reset_password/confirm/#{request.token}"
    assert email.html_body =~ request.source_ip
    assert email.html_body =~ "https://TEST_FRONTEND/reset_password/confirm/#{request.token}"
  end
end
