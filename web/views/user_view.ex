defmodule CaptainFact.UserView do
  use CaptainFact.Web, :view

  alias CaptainFact.{UserView}

  def render("index_public.json", %{users: users}) do
    render_many(users, UserView, "public_user.json")
  end

  def render("show.json", %{user: user, token: token}) do
    render_one(user, UserView, "user_token.json", token: token)
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
      registered_at: registered_at(user)
    }
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      name: user.name,
      username: user.username,
      reputation: user.reputation,
      registered_at: registered_at(user)
    }
  end

  def render("user_token.json", %{user: user, token: token}) do
    %{
      id: user.id,
      email: user.email,
      name: user.name,
      username: user.username,
      reputation: user.reputation,
      token: token
    }
  end

  defp registered_at(%{inserted_at: naive_datetime}) do
    naive_datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_date()
  end
end
