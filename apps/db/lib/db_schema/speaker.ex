defmodule DB.Schema.Speaker do
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.Changeset


  schema "speakers" do
    field :full_name, :string
    field :title, :string
    field :slug, :string
    field :country, :string
    field :wikidata_item_id, :integer
    field :is_user_defined, :boolean, default: true
    field :picture, DB.Type.SpeakerPicture.Type
    field :is_removed, :boolean, default: false

    has_many :statements, DB.Schema.Statement, on_delete: :nilify_all
    many_to_many :videos, DB.Schema.Video, join_through: "videos_speakers", on_delete: :delete_all

    timestamps()
  end

  @required_fields ~w(full_name)
  @optional_fields ~w(title wikidata_item_id country)
  @optional_file_fields ~w(picture)

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_attachments(params, @optional_file_fields)
    |> update_change(:full_name, &DB.Utils.String.trim_all_whitespaces/1)
    |> update_change(:title, &DB.Utils.String.trim_all_whitespaces/1)
    |> validate_length(:full_name, min: 3, max: 60)
    |> validate_length(:title, min: 3, max: 60)
    |> validate_required(:full_name)
    |> unique_constraint(:wikidata_item_id)
  end

  @doc """
  Builds a deletion changeset for `struct`
  """
  def changeset_remove(struct) do
    cast(struct, %{is_removed: true}, [:is_removed])
  end

  @doc """
  Builds a restore changeset for `struct`
  """
  def changeset_restore(struct) do
    cast(struct, %{is_removed: false}, [:is_removed])
  end

  @doc """
  Builds a changeset to validate speaker, setting user_defined to false and generate a slug
  """
  def changeset_validate_speaker(struct = %{full_name: name}) do
    struct
    |> Ecto.Changeset.change(is_user_defined: false)
    |> Ecto.Changeset.put_change(:slug, Slugger.slugify(name))
    |> unique_constraint(:slug)
  end
end
