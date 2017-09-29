defmodule CaptainFactWeb.VideoController do
  use CaptainFactWeb, :controller
  import CaptainFact.Videos

  action_fallback CaptainFactWeb.FallbackController


  def index(conn, %{"language" => language}),
    do: render(conn, :index, videos: videos_list(language))
  def index(conn, _params),
    do: render(conn, :index, videos: videos_list())

  def get_or_create(conn, %{"url" => url}) do
    case get_video_by_url(url) do
      nil ->
        Guardian.Plug.current_resource(conn)
        |> create!(url)
        |> case do
             {:error, message} -> json(put_status(conn, :unprocessable_entity), %{error: %{url: message}})
             video -> render(conn, "show.json", video: video)
           end
      video -> render(conn, "show.json", video: video)
    end
  end

  def search(conn, %{"url" => url}) do
    case get_video_by_url(url) do
      nil -> send_resp(conn, 204, "")
      video -> render(conn, "show.json", video: video)
    end
  end
end
