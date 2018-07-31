defmodule CaptainFactMailer.View do
  use Phoenix.View, root: "lib/captain_fact_mailer/templates", namespace: CaptainFactMailer
  use Phoenix.HTML

  import CaptainFact.Gettext

  def frontend_url do
    Application.fetch_env!(:captain_fact, :frontend_url)
  end

  def user_appelation(user) do
    DB.Schema.User.user_appelation(user)
  end
end
