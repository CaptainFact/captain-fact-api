defmodule CaptainFactWeb.VideoController do
  use CaptainFactWeb, :controller

  alias CaptainFactWeb.Video
  alias CaptainFact.Accounts.UserPermissions

  action_fallback CaptainFactWeb.FallbackController

  def index(conn, %{"language" => language}) do
    videos =
      Video
      |> Video.with_speakers
      |> where([v], language: ^language)
      |> order_by([v], desc: v.id)
      |> Repo.all()
    render(conn, :index, videos: videos)
  end

  def index(conn, _params) do
    videos =
      Video
      |> Video.with_speakers
      |> order_by([v], desc: v.id)
      |> Repo.all()
    render(conn, :index, videos: videos)
  end

  def get_or_create(conn, %{"url" => url}) do
    case get_video_by_url(url) do
      nil -> create(conn, url)
      video -> render(conn, "show.json", video: video)
    end
  end

  defp create(conn, video_url) do
    user = Guardian.Plug.current_resource(conn)
    # Unsafe check before request just to ensure user is not using this method to DDOS youtube
    UserPermissions.check!(user, :add_video)

    case fetch_video_metadata(video_url) do
      {:error, message} ->
        put_status(conn, :unprocessable_entity)
        |> json(%{error: %{url: message}})
      {:ok, metadata} ->
        changeset = Video.changeset(%Video{}, metadata)
        video =
          UserPermissions.lock!(user, :add_video, fn _ -> Repo.insert!(changeset) end)
          |> Map.put(:speakers, [])
        render(conn, "show.json", video: video)
    end
  end

  def search(conn, %{"url" => url}) do
    case get_video_by_url(url) do
      nil -> send_resp(conn, 204, "")
      video -> render(conn, "show.json", video: video)
    end
  end

  defp get_video_by_url(url) do
    case Video.parse_url(url) do
      {provider, id} -> Repo.get_by(Video.with_speakers(Video), provider: provider, provider_id: id)
      nil -> nil
    end
  end

  defp fetch_video_metadata(nil), do: {:error, "Invalid URL"}
  defp fetch_video_metadata(url) when is_binary(url), do: fetch_video_metadata(Video.parse_url(url))
  defp fetch_video_metadata({"youtube", video_id}) do
    case Application.get_env(:captain_fact, :youtube_api_key) do
      nil -> fetch_video_metadata_html("youtube", video_id)
      api_key -> fetch_video_metadata_api("youtube", video_id, api_key)
    end
  end

  defp fetch_video_metadata_api("youtube", video_id, api_key) do
    case HTTPoison.get("https://www.googleapis.com/youtube/v3/videos?id=#{video_id}&part=snippet&key=#{api_key}") do
      {:ok, %HTTPoison.Response{body: body}} ->
        # Parse JSON and extract intresting info
        full_metadata = Poison.decode!(body) |> Map.get("items") |> List.first()
        if full_metadata == nil do
          {:error, "Video doesn't exist"}
        else
          {:ok, %{
            title: full_metadata["snippet"]["title"],
            language: full_metadata["snippet"]["defaultLanguage"] || full_metadata["snippet"]["defaultAudioLanguage"],
            url: Video.build_url(%{provider: "youtube", provider_id: video_id})
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
