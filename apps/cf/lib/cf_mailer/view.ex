defmodule CF.Mailer.View do
  use Phoenix.View, root: "lib/cf_mailer/templates", namespace: CF.Mailer
  use Phoenix.HTML

  import CF.Gettext
  import CF.Utils.FrontendRouter

  def user_appelation(user) do
    DB.Schema.User.user_appelation(user)
  end
end
