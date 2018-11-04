defmodule CF.Gettext do
  use Gettext, otp_app: :cf

  defmacro with_user_locale(user, do: expression) do
    quote do
      locale = Map.get(unquote(user), :locale) || "en"

      Gettext.with_locale(CF.Gettext, locale, fn ->
        unquote(expression)
      end)
    end
  end

  defmacro gettext_mail(msgid, vars \\ []) do
    quote do
      CF.Gettext.dgettext("mail", unquote(msgid), unquote(vars))
    end
  end

  defmacro gettext_mail_user(user, msgid, vars \\ []) do
    quote do
      locale = Map.get(unquote(user), :locale) || "en"

      Gettext.with_locale(CF.Gettext, locale, fn ->
        CF.Gettext.dgettext("mail", unquote(msgid), unquote(vars))
      end)
    end
  end
end
