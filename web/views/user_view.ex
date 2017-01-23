defmodule CaptainFact.UserView do
  use CaptainFact.Web, :view

  alias CaptainFact.{UserView}

  def render("show.json", %{user: user, token: token}) do
    %{data: render_one(user, UserView, "user_token.json", token: token)}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, CaptainFact.UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{id: user.id,
      email: user.email,
      name: user.name,
      nickname: user.nickname
    }
  end

  def render("user_token.json", %{user: user, token: token}) do
    %{id: user.id,
      email: user.email,
      name: user.name,
      nickname: user.nickname,
      token: token
    }
  end
end
