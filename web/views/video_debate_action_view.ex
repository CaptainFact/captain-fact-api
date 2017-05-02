defmodule CaptainFact.VideoDebateActionView do
  use CaptainFact.Web, :view

  alias CaptainFact.{ VideoDebateActionView, UserView }

  def render("index.json", %{video_debate_actions: actions}) do
    render_many(actions, VideoDebateActionView, "video.json")
  end

  def render("show.json", %{video_debate_action: action}) do
    render_one(action, VideoDebateActionView, "action.json")
  end

  def render("action.json", %{video_debate_action: action}) do
    %{
      id: action.id,
      user: UserView.render("show_public.json", %{user: action.user}),
      time: action.inserted_at,
      video_id: action.video_id,
      entity: action.entity,
      entity_id: action.entity_id,
      type: action.type,
      changes: action.changes
    }
  end
end
