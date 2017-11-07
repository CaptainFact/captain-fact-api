defmodule CaptainFactWeb.UserActionView do
  use CaptainFactWeb, :view

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
      context: action.context,
      entity: action.entity,
      entity_id: action.entity_id,
      changes: action.changes,
      time: action.inserted_at
    }
  end
end
