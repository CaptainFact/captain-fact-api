defmodule CF.Videos.CaptionsFetcher do
  @moduledoc """
  Fetch captions for videos.
  """

  @callback fetch(DB.Schema.Video.t()) :: {:ok, DB.Schema.VideoCaption.t()} | {:error, binary()}
end
