defmodule CF.Videos.MetadataFetcher do
  @moduledoc """
  Fetch metadata for video.
  """

  @type video_metadata :: %{
          title: String.t(),
          language: String.t(),
          url: String.t()
        }

  @doc """
  Takes an URL, fetch the metadata and return them
  """
  @callback fetch_video_metadata(String.t()) :: {:ok, video_metadata} | {:error, binary()}
end
