defmodule CF.Web.FlagView do
  use CF.Web, :view

  alias CF.Web.UserView

  def render("flag_without_action.json", %{flag: flag}) do
    %{
      source_user: UserView.render("show.json", user: flag.source_user),
      reason: flag.reason
    }
  end
end
