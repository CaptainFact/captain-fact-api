defmodule CaptainFact.Videos.MetadataFetcher do
  @moduledoc """
  Methods to fetch metadata (title, language) from videos
  """

  require Logger

  alias Kaur.Result
  alias GoogleApi.YouTube.V3.Connection, as: YouTubeConnection
  alias GoogleApi.YouTube.V3.Api.Videos, as: YouTubeVideos
  alias GoogleApi.YouTube.V3.Model.Video, as: YouTubeVideo
  alias GoogleApi.YouTube.V3.Model.VideoListResponse, as: YouTubeVideoList

  alias DB.Schema.Video

  @doc """
  Fetch metadata from video. Returns an object containing  :title, :url and :language

  Usage:
  iex> fetch_video_metadata("https://www.youtube.com/watch?v=OhWRT3PhMJs")
  iex> fetch_video_metadata({"youtube", "OhWRT3PhMJs"})
  """
  def fetch_video_metadata(nil),
    do: {:error, "Invalid URL"}

  if Application.get_env(:db, :env) == :test do
    def fetch_video_metadata(url = "__TEST__/" <> _id) do
      {:ok, %{title: "__TEST-TITLE__", url: url}}
    end
  end

  def fetch_video_metadata(url) when is_binary(url),
    do: fetch_video_metadata(Video.parse_url(url))

  def fetch_video_metadata({"youtube", provider_id}) do
    case Application.get_env(:captain_fact, :youtube_api_key) do
      nil ->
        Logger.warn("No YouTube API key provided. Falling back to HTML fetcher")
        fetch_video_metadata_html("youtube", provider_id)

      api_key ->
        fetch_video_metadata_api("youtube", provider_id, api_key)
    end
  end

  defp fetch_video_metadata_api("youtube", provider_id, api_key) do
    YouTubeConnection.new()
    |> YouTubeVideos.youtube_videos_list("snippet", id: provider_id, key: api_key)
    |> Result.map_error(fn e -> "YouTube API Error: #{inspect(e)}" end)
    |> Result.keep_if(&(!Enum.empty?(&1.items)), "Video doesn't exist")
    |> Result.map(fn %YouTubeVideoList{items: [video = %YouTubeVideo{} | _]} ->
      %{
        title: video.snippet.title,
        language: video.snippet.defaultLanguage || video.snippet.defaultAudioLanguage,
        url: Video.build_url(%{provider: "youtube", provider_id: provider_id})
      }
    end)
  end

  defp fetch_video_metadata_html(provider, id) do
    url = Video.build_url(%{provider: provider, provider_id: id})

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{body: body}} ->
        meta = Floki.attribute(body, "meta[property='og:title']", "content")

        case meta do
          [] -> {:error, "Page does not contains an OpenGraph title attribute"}
          [title] -> {:ok, %{title: HtmlEntities.decode(title), url: url}}
        end

      {_, _} ->
        {:error, "Remote URL didn't respond correctly"}
    end
  end
end
