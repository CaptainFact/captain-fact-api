defmodule CaptainFact.VideoController do
  use CaptainFact.Web, :controller

  alias CaptainFact.{Video}

  plug Guardian.Plug.EnsureAuthenticated, [handler: CaptainFact.AuthController]
  when action in [:get_or_create, :video_title]

  def index(conn, _params) do
    videos = Video
    |> Video.with_speakers
    |> order_by([v], desc: v.id)
    |> Repo.all()
    render(conn, :index, videos: videos)
  end

  def get_or_create(conn, video_params) do
    video_url = Video.format_url(video_params["url"])
    case Repo.get_by(Video.with_speakers(Video), url: video_url) do
      nil -> create(conn, video_url)
      video -> render(conn, "show.json", video: video)
    end
  end

  defp create(conn, video_url) do
    case fetch_video_title(video_url) do
      {:error, message} ->
        put_status(conn, :unprocessable_entity)
        |> json(%{error: %{url: message}})
      {:ok, title} ->
        changeset = Video.changeset(%Video{title: title}, %{url: video_url})
        case Repo.insert(changeset) do
          {:ok, video} ->
            video = Map.put(video, :speakers, [])
            render(conn, "show.json", video: video)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(CaptainFact.ChangesetView, :error, changeset: changeset)
        end
    end
  end

  def search(conn, %{"url" => url}) do
    video_url = Video.format_url(url)
    case Repo.get_by(Video.with_speakers(Video), url: video_url) do
      nil -> send_resp(conn, 200, "{}")
      video -> render(conn, "show.json", video: video)
    end
  end

#  defp video_title(conn, %{"video_uri" => video_uri}) do
#    case fetch_video_title(video_uri) do
#      {:ok, title} -> json(conn, %{title: title})
#      {:error, message} ->
#        conn
#        |> put_status(404)
#        |> json(%{error: message})
#    end
#  end

  defp fetch_video_title(url) do
    if Regex.match?(~r/(?:youtube\.com\/\S*(?:(?:\/e(?:mbed))?\/|watch\/?\?(?:\S*?&?v\=))|youtu\.be\/)([a-zA-Z0-9_-]{6,11})/, url) do
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{body: body}} ->
          meta = Floki.attribute(body, "meta[property='og:title']", "content")
          case meta do
            [] -> {:error, "Page does not contains an OpenGraph title attribute"}
            [title] -> {:ok, HtmlEntities.decode(title)}
          end
        {_, _} -> {:error, "Remote URL didn't respond correctly"}
      end
    else
      {:error, "Invalid URL"}
    end
  end
end
