defmodule CaptainFact.Videos.MetadataFetcher do
  @moduledoc """
  Methods to fetch metadata (title, language) from videos
  """

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
        fetch_video_metadata_html("youtube", provider_id)
      api_key ->
        fetch_video_metadata_api("youtube", provider_id, api_key)
    end
  end

  defp fetch_video_metadata_api("youtube", provider_id, api_key) do
    case HTTPoison.get("https://www.googleapis.com/youtube/v3/videos?id=#{provider_id}&part=snippet&key=#{api_key}") do
      {:ok, %HTTPoison.Response{body: body}} ->
        # Parse JSON and extract intresting info
        full_metadata =
          body
          |> Poison.decode!()
          |> Map.get("items")
          |> List.first()

        if full_metadata == nil do
          {:error, "Video doesn't exist"}
        else
          {:ok, %{
            title: full_metadata["snippet"]["title"],
            language: full_metadata["snippet"]["defaultLanguage"] || full_metadata["snippet"]["defaultAudioLanguage"],
            url: Video.build_url(%{provider: "youtube", provider_id: provider_id})
          }}
        end
      {_, _} ->
        {:error, "Remote URL didn't respond correctly"}
    end
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