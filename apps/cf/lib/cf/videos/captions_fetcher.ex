defmodule CF.Videos.CaptionsFetcher do
  @moduledoc """
  Fetch captions for videos.
  """

  @callback fetch(String.t(), String.t()) ::
              {:ok, DB.Schema.VideoCaption.t()} | {:error, binary()}
end
