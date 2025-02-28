defmodule CF.RestApi.CategoryView do
  use CF.RestApi, :view

  def render("category.json", %{category: category}) do
    %{
      id: category.id,
      slug: category.slug
    }
  end
end
