defmodule CF.RestApi.ModerationEntryView do
  use CF.RestApi, :view

  alias CF.Moderation.ModerationEntry
  alias CF.RestApi.UserActionView
  alias CF.RestApi.FlagView

  def render("show.json", %{moderation_entry: %ModerationEntry{action: action, flags: flags}}) do
    %{
      action: render(UserActionView, "user_action.json", %{user_action: action}),
      flags: render_many(flags, FlagView, "flag_without_action.json")
    }
  end
end
