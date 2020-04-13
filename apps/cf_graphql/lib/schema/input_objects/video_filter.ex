defmodule CF.Graphql.Schema.InputObjects.VideoFilter do
  @moduledoc """
  Represent a user's Notification.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo

  @desc "Props to filter videos on"
  input_object :video_filter do
    field(:language, :string)
    field(:min_id, :id)
    field(:speaker_id, :id)
    field(:speaker_slug, :string)
    field(:is_partner, :boolean)
    field(:is_featured, :boolean)
  end
end
