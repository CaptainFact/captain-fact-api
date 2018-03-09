defmodule CaptainFact.Email do
  import Bamboo.Email
  require CaptainFactJobs.Reputation

  alias DB.Repo
  alias DB.Schema.ResetPasswordRequest
  alias DB.Schema.InvitationRequest
  alias DB.Schema.User

  alias CaptainFactJobs.Reputation

  # TODO GetText i18n

  @cf_no_reply {"CaptainFact", "no-reply@captainfact.io"}
  @confirm_email_reputation elem(Reputation.action_reputation_change(:email_confirmed), 0)
  @main_font_family "Ubuntu, Lato, Tahoma, sans-serif"


  # Welcome + verify email

  def welcome_email(user) do
    new_email(from: @cf_no_reply)
    |> to(user)
    |> subject("Welcome to CaptainFact.io !")
    |> build_html_body("""
       Welcome to CaptainFact.io ! To confirm your email and gain a bonus of
       +#{@confirm_email_reputation} reputation, click on this link :
       <a href="#{frontend_url()}/confirm_email/#{user.email_confirmation_token}">Confirm my email</a>
       <br/><br/>
       You can learn more about how the system works and the whys of CaptainFact by checking
       <a href="#{frontend_url()}/help">the help pages</a>.
       <br/><br/>
       Feel free to contact us at contact@captainfact.io if you want to share something with us or if you
       want to contribute to the project but don't know where to start with!
       """)
  end

  def newsletter(%{newsletter: false}, _, _), do: nil
  def newsletter(user, subject, html_message) do
    new_email(from: @cf_no_reply)
    |> to(user)
    |> subject(subject)
    |> build_html_body(
         html_message,
         """
           <a href="#{frontend_url()}/newsletter/unsubscribe/#{user.newsletter_subscription_token}" style="font-size: 15px;text-align: center;font-family: #{@main_font_family};background: aliceblue;padding: 1em;display: block;">
             Unsubscribe from this newsletter
           </a>
         """
       )
  end

  # Reset password

  def reset_password_request_mail(req = %ResetPasswordRequest{user: %Ecto.Association.NotLoaded{}}),
    do: reset_password_request_mail(Repo.preload(req, :user))
  def reset_password_request_mail(%ResetPasswordRequest{user: user, token: token, source_ip: ip}) do
    new_email(from: @cf_no_reply)
    |> to(user)
    |> subject("CaptainFact.io - Reset your password")
    |> build_html_body("""
       You recently asked to reset your password on <a href="https://captainfact.io">CaptainFact</a>. Click on this link
       to do so: <a href="#{frontend_url()}/reset_password/confirm/#{token}">Reset pasword</a>
       <br/><br/>
       Please ignore this email if the request is not comming from you.
       <br/><br/>
       <span style="color: grey; font-style: italic; font-size: 11px;">Reset requested by IP: #{ip}</span>
       """)
  end

  # Invitation

  def invite_user_email(req = %InvitationRequest{invited_by: %Ecto.Association.NotLoaded{}}),
    do: invite_user_email(Repo.preload(req, :invited_by))
  def invite_user_email(%InvitationRequest{invited_by: invited_by, email: email, token: token}) do
    new_email(from: @cf_no_reply)
    |> to(email)
    |> subject(invitation_subject(invited_by))
    |> build_html_body("""
       Your invitation to try CaptainFact is ready !
       <br/><br/>
       Please follow this link to create your account:
       <a href="#{frontend_url()}/signup?invitation_token=#{token}">Create account</a>
       """)
  end

  @doc"""
  Prepare an email with a default template
  """
  def build_html_body(mail, content, content_footer \\ "") do
    html_body(mail, """
    <!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
    <head>
    <title></title>
    <!--[if !mso]><!-- -->
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <!--<![endif]-->
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style type="text/css">  #outlook a { padding: 0; }  .ReadMsgBody { width: 100%; }  .ExternalClass { width: 100%; }  .ExternalClass * { line-height:100%; }  body { margin: 0; padding: 0; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }  table, td { border-collapse:collapse; mso-table-lspace: 0pt; mso-table-rspace: 0pt; }  img { border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; }  p { display: block; margin: 13px 0; }</style>
    <!--[if !mso]><!-->
    <style type="text/css">  @media only screen and (max-width:480px) {    @-ms-viewport { width:320px; }    @viewport { width:320px; }  }</style>
    <!--<![endif]--><!--[if mso]>
    <xml>
      <o:OfficeDocumentSettings>
        <o:AllowPNG/>
        <o:PixelsPerInch>96</o:PixelsPerInch>
      </o:OfficeDocumentSettings>
    </xml>
    <![endif]--><!--[if lte mso 11]>
    <style type="text/css">  .outlook-group-fix {    width:100% !important;  }</style>
    <![endif]-->
    <style type="text/css">  @media only screen and (min-width:480px) {    .mj-column-per-100 { width:100%!important; }.mj-column-per-50 { width:50%!important; }  }</style>
    </head>
    <body style="background: #FFFFFF;">
    <div class="mj-container" style="background-color:#FFFFFF;">
      <!--[if mso | IE]>
      <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="600" align="center" style="width:600px;">
        <tr>
          <td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;">
            <![endif]-->
            <table role="presentation" cellpadding="0" cellspacing="0" style="background:#49a6e8;font-size:0px;width:100%;" border="0">
              <tbody>
                <tr>
                  <td>
                    <div style="margin:0px auto;max-width:600px;">
                      <table role="presentation" cellpadding="0" cellspacing="0" style="font-size:0px;width:100%;" align="center" border="0">
                        <tbody>
                          <tr>
                            <td style="text-align:center;vertical-align:top;direction:ltr;font-size:0px;padding:0px 0px 0px 0px;">
                              <!--[if mso | IE]>
                              <table role="presentation" border="0" cellpadding="0" cellspacing="0">
                                <tr>
                                  <td style="vertical-align:top;width:600px;">
                                    <![endif]-->
                                    <div class="mj-column-per-100 outlook-group-fix" style="vertical-align:top;display:inline-block;direction:ltr;font-size:13px;text-align:left;width:100%;">
                                      <table role="presentation" cellpadding="0" cellspacing="0" width="100%" border="0">
                                        <tbody>
                                          <tr>
                                            <td style="word-wrap:break-word;font-size:0px;">
                                              <div style="font-size:1px;line-height:28px;white-space:nowrap;">&#xA0;</div>
                                            </td>
                                          </tr>
                                          <tr>
                                            <td style="word-wrap:break-word;font-size:0px;padding:0px 0px 0px 0px;" align="center">
                                              <table role="presentation" cellpadding="0" cellspacing="0" style="border-collapse:collapse;border-spacing:0px;" align="center" border="0">
                                                <tbody>
                                                  <tr>
                                                    <td style="width:90px;"><img alt="" title="" height="auto" src="https://captainfact.io/assets/img/logo.png" style="border:none;border-radius:0px;display:block;font-size:13px;outline:none;text-decoration:none;width:100%;height:auto;" width="90"></td>
                                                  </tr>
                                                </tbody>
                                              </table>
                                            </td>
                                          </tr>
                                          <tr>
                                            <td style="word-wrap:break-word;font-size:0px;padding:0px 20px 0px 20px;" align="center">
                                              <div style="cursor:auto;color:#FFFFFF;font-family:#{@main_font_family};font-size:14px;line-height:22px;text-align:center;">
                                                <h1 style="font-family: &apos;Cabin&apos;, sans-serif; color: #FFFFFF; font-size: 32px; line-height: 100%;"><span style="font-size:48px;">CaptainFact</span></h1>
                                              </div>
                                            </td>
                                          </tr>
                                          <tr/>
                                        </tbody>
                                      </table>
                                    </div>
                                    <!--[if mso | IE]>
                                  </td>
                                </tr>
                              </table>
                              <![endif]-->
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
            <!--[if mso | IE]>
          </td>
        </tr>
      </table>
      <![endif]-->      <!--[if mso | IE]>
      <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="600" align="center" style="width:600px;">
        <tr>
          <td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;">
            <![endif]-->
            <table role="presentation" cellpadding="0" cellspacing="0" style="font-size:0px;width:100%;" border="0">
              <tbody>
                <tr>
                  <td>
                    <div style="margin:0px auto;max-width:600px;">
                      <table role="presentation" cellpadding="0" cellspacing="0" style="font-size:0px;width:100%;" align="center" border="0">
                        <tbody>
                          <tr>
                            <td style="text-align:center;vertical-align:top;direction:ltr;font-size:0px;padding:9px 0px 9px 0px;">
                              <!--[if mso | IE]>
                              <table role="presentation" border="0" cellpadding="0" cellspacing="0">
                                <tr>
                                  <td style="vertical-align:top;width:600px;">
                                    <![endif]-->
                                    <div class="mj-column-per-100 outlook-group-fix" style="vertical-align:top;display:inline-block;direction:ltr;font-size:13px;text-align:left;width:100%;">
                                      <table role="presentation" cellpadding="0" cellspacing="0" width="100%" border="0">
                                        <tbody>
                                          <tr>
                                            <td style="word-wrap:break-word;font-size:0px;">
                                              <div style="font-size:1px;line-height:15px;white-space:nowrap;">&#xA0;</div>
                                            </td>
                                          </tr>
                                          <tr>
                                            <td style="word-wrap:break-word;font-size:0px;padding:0px 20px 0px 20px;" align="left">
                                              <div style="font-size:14px;cursor:auto;color:#000000;font-family:#{@main_font_family};line-height:22px;text-align:left;">
                                                #{content}
                                              </div>
                                            </td>
                                          </tr>
                                          <tr>
                                            <td style="word-wrap:break-word;font-size:0px;">
                                              #{content_footer}
                                            </td>
                                          </tr>
                                          <tr>
                                            <td style="word-wrap:break-word;font-size:0px;padding:10px 25px;padding-top:10px;padding-bottom:10px;padding-right:10px;padding-left:10px;">
                                              <p style="font-size:1px;margin:0px auto;border-top:1px solid #E2E2E2;width:100%;"></p>
                                              <!--[if mso | IE]>
                                              <table role="presentation" align="center" border="0" cellpadding="0" cellspacing="0" style="font-size:1px;margin:0px auto;border-top:1px solid #E2E2E2;width:100%;" width="600">
                                                <tr>
                                                  <td style="height:0;line-height:0;"> </td>
                                                </tr>
                                              </table>
                                              <![endif]-->
                                            </td>
                                          </tr>
                                        </tbody>
                                      </table>
                                    </div>
                                    <!--[if mso | IE]>
                                  </td>
                                </tr>
                              </table>
                              <![endif]-->
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
            <!--[if mso | IE]>
          </td>
        </tr>
      </table>
      <![endif]-->      <!--[if mso | IE]>
      <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="600" align="center" style="width:600px;">
        <tr>
          <td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;">
            <![endif]-->
            <table role="presentation" cellpadding="0" cellspacing="0" style="font-size:0px;width:100%;" border="0">
              <tbody>
                <tr>
                  <td>
                    <div style="margin:0px auto;max-width:600px;">
                      <table role="presentation" cellpadding="0" cellspacing="0" style="font-size:0px;width:100%;" align="center" border="0">
                        <tbody>
                          <tr>
                            <td style="text-align:center;vertical-align:top;direction:ltr;font-size:0px;padding:0px 0px 0px 0px;">
                              <!--[if mso | IE]>
                              <table role="presentation" border="0" cellpadding="0" cellspacing="0">
                                <tr>
                                  <td style="vertical-align:top;width:300px;">
                                    <![endif]-->
                                    <div class="mj-column-per-50 outlook-group-fix" style="vertical-align:top;display:inline-block;direction:ltr;font-size:13px;text-align:left;width:100%;">
                                      <table role="presentation" cellpadding="0" cellspacing="0" width="100%" border="0">
                                        <tbody>
                                          <tr>
                                            <td style="word-wrap:break-word;font-size:0px;padding:0px 20px 0px 20px;" align="left">
                                              <div style="cursor:auto;color:#949494;font-family:#{@main_font_family};font-size:14px;line-height:22px;text-align:left;">
                                                <p>CaptainFact is a free and open source project. If you like it, please share the word!<br><span style="font-size:12px;">&#xA0;</span></p>
                                              </div>
                                            </td>
                                          </tr>
                                        </tbody>
                                      </table>
                                    </div>
                                    <!--[if mso | IE]>
                                  </td>
                                  <td style="vertical-align:top;width:300px;">
                                    <![endif]-->
                                    <div class="mj-column-per-50 outlook-group-fix" style="vertical-align:top;display:inline-block;direction:ltr;font-size:13px;text-align:left;width:100%;">
                                      <span style="font-size: 14px;">
                                        <ul style="font-family: #{@main_font_family};">
                                          <li><a href="https://github.com/CaptainFact">Github</a></li>
                                          <li><a href="https://www.facebook.com/CaptainFact.io/">Facebook</a></li>
                                          <li><a href="https://twitter.com/CaptainFact_io">Twitter</a></li>
                                        </ul>
                                      </span>
                                      <table role="presentation" cellpadding="0" cellspacing="0" width="100%" border="0">
                                        <tbody></tbody>
                                      </table>
                                    </div>
                                    <!--[if mso | IE]>
                                  </td>
                                </tr>
                              </table>
                              <![endif]-->
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
            <!--[if mso | IE]>
          </td>
        </tr>
      </table>
      <![endif]-->
    </div>
    </body>
    </html>
    """)
  end

  defp frontend_url, do: Application.fetch_env!(:captain_fact, :frontend_url)

  defp invitation_subject(nil),
    do: "Your invitation to try CaptainFact.io is ready !"
  defp invitation_subject(user = %User{}),
    do: "#{User.user_appelation(user)} invited you to try CaptainFact.io !"
end