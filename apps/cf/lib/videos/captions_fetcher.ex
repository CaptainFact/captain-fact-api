defmodule CF.Videos.CaptionsFetcher do
  @moduledoc """
  Fetch captions for videos.
  """

  @callback fetch(DB.Schema.Video.t()) ::
              {:ok, %{raw: String.t(), parsed: String.t(), format: String.t()}} | {:error, term()}
end
