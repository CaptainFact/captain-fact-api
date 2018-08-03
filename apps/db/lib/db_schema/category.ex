defmodule DB.Schema.Category do
  @moduledoc """
  Ecto Schema for `category` table.
  """

  use Ecto.Schema

  schema "categories" do
    field(:title, :string)

    many_to_many(:videos, Video, join_through: "category_videos", on_delete: :delete_all)

    timestamps()
  end
end
