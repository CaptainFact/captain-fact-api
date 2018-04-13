defmodule CaptainFactWeb.UserActionView do
  use CaptainFactWeb, :view

  alias DB.Schema.UserAction
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
      entity_id: action.entity_id,
      changes: action.changes,
      time: action.inserted_at,
    }
  end

  def render("user_action_with_context.json", %{user_action: action}) do
    %{
      id: action.id,
      user: UserView.render("show_public.json", %{user: action.user}),
      type: action.type,
      entity: action.entity,
      entity_id: action.entity_id,
      changes: action.changes,
      time: action.inserted_at,
      context: context_expander(action)
    }
  end

  @create UserAction.type(:create)
  @comment UserAction.entity(:comment)
  defp context_expander(action = %{type: @create, entity: @comment, context: "VD:" <> video_id}) do
    %{
      type: "video",
      hash_id: DB.Type.VideoHashId.encode(String.to_integer(video_id)),
      statement_id: action.changes[:statement_id]
    }
  end
  defp context_expander(_) do
    nil
  end
end
