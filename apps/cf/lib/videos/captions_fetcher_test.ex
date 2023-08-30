defmodule CF.Videos.CaptionsFetcherTest do
  @moduledoc """
  A mock for faking captions fetching requests.
  """

  @behaviour CF.Videos.CaptionsFetcher

  @impl true
  def fetch(_video) do
    captions = %{
      raw: "__TEST-CONTENT__",
      format: "custom",
      parsed: [
        %{
          "text" => "__TEST-CONTENT__",
          "start" => 0.0,
          "duration" => 1.0
        }
      ]
    }

    {:ok, captions}
  end
end
