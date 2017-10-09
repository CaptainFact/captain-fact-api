defmodule CaptainFactWeb.UserActionView do
  use CaptainFactWeb, :view

  alias CaptainFactWeb.{UserActionView, UserView}

  def render("index.json", %{user_actions: actions}) do
    render_many(actions, UserActionView, "action.json")
  end

  def render("show.json", %{user_actions: action}) do
    render_one(action, UserActionView, "action.json")
  end

  def render("action.json", %{user_action: action}) do
    %{
      id: action.id,
      user: UserView.render("show_public.json", %{user: action.user}),
      # TODO target_user: ???,
      context: action.context,
      type: action.type,
      entity: action.entity,
      entity_id: action.entity_id,
      changes: action.changes,
      time: action.inserted_at,
    }
  end
end
