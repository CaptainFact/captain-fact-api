defmodule CF.Videos.MetadataFetcher.Youtube do
  @moduledoc """
  Methods to fetch metadata (title, language) from videos
  """

  @behaviour CF.Videos.MetadataFetcher

  require Logger

  alias Kaur.Result
  alias GoogleApi.YouTube.V3.Connection, as: YouTubeConnection
  alias GoogleApi.YouTube.V3.Api.Videos, as: YouTubeVideos
  alias GoogleApi.YouTube.V3.Model.Video, as: YouTubeVideo
  alias GoogleApi.YouTube.V3.Model.VideoListResponse, as: YouTubeVideoList

  alias DB.Schema.Video
  alias CF.Videos.MetadataFetcher

  @doc """
  Fetch metadata from video. Returns an object containing  :title, :url and :language
  """
  def fetch_video_metadata(nil),
    do: {:error, "Invalid URL"}

  def fetch_video_metadata(url) when is_binary(url) do
    {:youtube, youtube_id} = Video.parse_url(url)

    case Application.get_env(:cf, :youtube_api_key) do
      nil ->
        Logger.warn("No YouTube API key provided. Falling back to HTML fetcher")
        MetadataFetcher.Opengraph.fetch_video_metadata(url)

      api_key ->
        do_fetch_video_metadata(youtube_id, api_key)
    end
  end

  defp do_fetch_video_metadata(youtube_id, api_key) do
    YouTubeConnection.new()
    |> YouTubeVideos.youtube_videos_list("snippet", id: youtube_id, key: api_key)
    |> Result.map_error(fn e -> "YouTube API Error: #{inspect(e)}" end)
    |> Result.keep_if(&(!Enum.empty?(&1.items)), "remote_video_404")
    |> Result.map(fn %YouTubeVideoList{items: [video = %YouTubeVideo{} | _]} ->
      %{
        title: video.snippet.title,
        language: video.snippet.defaultLanguage || video.snippet.defaultAudioLanguage,
        url: Video.build_url(%{youtube_id: youtube_id})
      }
    end)
  end
end
