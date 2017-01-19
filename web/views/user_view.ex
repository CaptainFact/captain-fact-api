defmodule CaptainFact.UserView do
  use CaptainFact.Web, :view
  def render("show.json", %{users: users}) do
    %{data: render_one(users, CaptainFact.UsersView, "users.json")}
  end

  def render("users.json", %{users: users}) do
    %{id: users.id,
      name: users.name,
      nickname: users.nickname,
      email: users.email}
  end
end
