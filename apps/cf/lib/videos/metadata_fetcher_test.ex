defmodule CF.Videos.MetadataFetcher.Test do
  @moduledoc """
  Methods to fetch metadata (title, language) from videos
  """

  @behaviour CF.Videos.MetadataFetcher

  @doc """
  Fetch metadata from video using OpenGraph tags.
  """
  def fetch_video_metadata(url) do
    {:ok,
     %{
       title: "__TEST-TITLE__",
       url: url
     }}
  end
end
