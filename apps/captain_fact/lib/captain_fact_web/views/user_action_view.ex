defmodule CaptainFactWeb.UserActionView do
  use CaptainFactWeb, :view

  alias DB.Type.VideoHashId
  alias CaptainFactWeb.UserView
  alias CaptainFactWeb.UserActionView

  def render("index.json", %{users_actions: actions}) do
    render_many(actions, UserActionView, "user_action.json")
  end

  def render("show.json", %{user_action: action}) do
    render_one(action, UserActionView, "user_action.json")
  end

  def render("user_action.json", %{user_action: action}) do
    %{
      id: action.id,
      user: UserView.render("show_public.json", %{user: action.user}),
      type: action.type,
      entity: action.entity,
      changes: action.changes,
      time: action.inserted_at,
      videoId: action.video_id,
      videoHashId: action.video_id && VideoHashId.encode(action.video_id),
      speakerId: action.speaker_id,
      statementId: action.statement_id,
      commentId: action.comment_id
    }
  end
end
