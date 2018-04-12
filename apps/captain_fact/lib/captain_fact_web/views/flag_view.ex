defmodule CaptainFactWeb.FlagView do
  use CaptainFactWeb, :view

  alias CaptainFactWeb.UserView


  def render("flag_without_action.json", %{flag: flag}) do
    %{
      source_user: UserView.render("show.json", user: flag.source_user),
      reason: flag.reason
    }
  end
end