defmodule CF.Graphql.Schema.InputObjects.VideoCaption do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo

  input_object :video_caption_input do
    field(:text, non_null(:string))
    field(:start, non_null(:float))
    field(:duration, :float)
  end
end
