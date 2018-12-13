defmodule DB.Schema.Category do
  @moduledoc """
  Ecto Schema for `category` table.
  """

  use Ecto.Schema

  alias DB.Schema.Video
  alias Ecto.Changeset
  alias Kaur.Result

  # This represent the maximum depth of category hierarchy.
  # A category without parent is of degree 0, each one of its children is of
  # degree 1 and each one of its grand children of degree 2.
  @max_depth_degree 2

  schema "categories" do
    field(:title, :string)
    field(:depth_degree, :integer)

    belongs_to(:parent, __MODULE__)

    many_to_many(:videos, Video, join_through: "category_videos", on_delete: :delete_all)

    timestamps()
  end

  @spec validate_parent_and_depth(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_parent_and_depth(changeset) do
    changeset
    |> fetch_field(:parent_id)
    |> case do
      nil -> change(changeset, :depth_degree, 0)
      parent_id ->
        __MODULE__
        |> Repo.get(parent_id)
        |> Result.from_value()
        |> Result.either(
          fn _ ->
            Changeset.add_error(changeset, :parent, "No category with id #{parent_id} has been found")
          end,
          fn parent = %__MODULE__{ depth_degree: parent_depth_degree } ->
            if parent_depth_degree >= @max_depth_degree do
              Changeset.add_error(changeset, :parent, "A category of depth degree #{@max_depth_degree} cannot have any child")
            else
              Changeset.change(changeset, :depth_degree, parent_depth_degree + 1)
            end
          end
        )
    end
  end
end
