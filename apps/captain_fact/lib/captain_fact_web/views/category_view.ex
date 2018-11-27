defmodule CaptainFactWeb.CategoryView do
  use CaptainFactWeb, :view

  def render("category.json", %{category: category}) do
    %{
      id: category.id,
      slug: category.slug
    }
  end
end
