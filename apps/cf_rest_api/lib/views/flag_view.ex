defmodule CF.RestApi.FlagView do
  use CF.RestApi, :view

  alias CF.RestApi.UserView

  def render("flag_without_action.json", %{flag: flag}) do
    %{
      source_user: UserView.render("show.json", user: flag.source_user),
      reason: flag.reason
    }
  end
end
