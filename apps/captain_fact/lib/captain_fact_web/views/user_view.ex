defmodule CaptainFactWeb.UserView do
  use CaptainFactWeb, :view

  alias CaptainFactWeb.UserView

  def render("index_public.json", %{users: users}) do
    render_many(users, UserView, "public_user.json")
  end

  def render("show.json", %{user: user}) do
    render_one(user, UserView, "user.json")
  end

  def render("show_public.json", %{user: user}) do
    render_one(user, UserView, "public_user.json")
  end

  def render("public_user.json", %{user: user}) do
    %{
      id: user.id,
      name: user.name,
      username: user.username,
      reputation: user.reputation,
      picture_url: DB.Type.UserPicture.url({user.picture_url, user}, :thumb),
      mini_picture_url: DB.Type.UserPicture.url({user.picture_url, user}, :mini_thumb),
      registered_at: user.inserted_at,
      achievements: user.achievements,
      speaker_id: user.speaker_id
    }
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      fb_user_id: user.fb_user_id,
      name: user.name,
      username: user.username,
      reputation: user.reputation,
      picture_url: DB.Type.UserPicture.url({user.picture_url, user}, :thumb),
      mini_picture_url: DB.Type.UserPicture.url({user.picture_url, user}, :mini_thumb),
      locale: user.locale,
      registered_at: user.inserted_at,
      achievements: user.achievements,
      is_publisher: user.is_publisher,
      speaker_id: user.speaker_id
    }
  end

  def render("user_with_token.json", %{user: user, token: token}) do
    %{
      user: UserView.render("show.json", %{user: user}),
      token: token
    }
  end
end
