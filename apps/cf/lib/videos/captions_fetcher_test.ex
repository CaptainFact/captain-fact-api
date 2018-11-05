defmodule CF.Videos.CaptionsFetcherTest do
  @moduledoc """
  A mock for faking captions fetching requests.
  """

  @behaviour CF.Videos.CaptionsFetcher

  @impl true
  def fetch(_provider_id, _locale) do
    captions = %DB.Schema.VideoCaption{
      content: "__TEST-CONTENT__",
      format: "xml"
    }

    {:ok, captions}
  end
end
