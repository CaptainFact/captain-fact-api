defmodule CaptainFact.Gettext do
  use Gettext, otp_app: :captain_fact

  defmacro with_user_locale(user, do: expression) do
    quote do
      locale = Map.get(unquote(user), :locale) || "en"
      Gettext.with_locale CaptainFact.Gettext, locale, fn ->
        unquote(expression)
      end
    end
  end

  defmacro gettext_mail(msgid, vars \\ []) do
    quote do
      CaptainFact.Gettext.dgettext("mail", unquote(msgid), unquote(vars))
    end
  end

  defmacro gettext_mail_user(user, msgid, vars \\ []) do
    quote do
      locale = Map.get(unquote(user), :locale) || "en"
      Gettext.with_locale CaptainFact.Gettext, locale, fn ->
        CaptainFact.Gettext.dgettext("mail", unquote(msgid), unquote(vars))
      end
    end
  end
end