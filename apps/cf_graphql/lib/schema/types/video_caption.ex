defmodule CF.Graphql.Schema.Types.VideoCaption do
  @moduledoc """
  A single caption for a video
  """

  use Absinthe.Schema.Notation

  @desc "Information about the application"
  object :video_caption do
    @desc "Caption text"
    field(:text, non_null(:string))
    @desc "Caption start time (in seconds)"
    field(:start, non_null(:float))
    @desc "Caption duration (in seconds)"
    field(:duration, :float)
  end
end
