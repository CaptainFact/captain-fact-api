defmodule CaptainFactWeb.ModerationEntryView do
  use CaptainFactWeb, :view

  alias CaptainFact.Moderation.ModerationEntry
  alias CaptainFactWeb.UserActionView
  alias CaptainFactWeb.FlagView

  def render("show.json", %{moderation_entry: %ModerationEntry{action: action, flags: flags}}) do
    %{
      action: render(UserActionView, "user_action_with_context.json", %{user_action: action}),
      flags: render_many(flags, FlagView, "flag_without_action.json")
    }
  end
end
