defmodule CaptainFactWeb.VideoController do
  use CaptainFactWeb, :controller

  alias CaptainFactWeb.Video
  alias CaptainFact.Accounts.UserPermissions


  def index(conn, _params) do
    videos = Video
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

    case fetch_video_title(video_url) do
      {:error, message} ->
        put_status(conn, :unprocessable_entity)
        |> json(%{error: %{url: message}})
      {:ok, title} ->
        changeset = Video.changeset(%Video{title: title}, %{url: video_url})
        result = UserPermissions.lock!(user, :add_video, fn _ -> Repo.insert(changeset) end)
        case result do
          {:ok, video} ->
            video = Map.put(video, :speakers, [])
            render(conn, "show.json", video: video)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(CaptainFactWeb.ChangesetView, :error, changeset: changeset)
        end
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

  defp fetch_video_title(url) do
    # Ensure url is valid and cleans it by parsing then rebuilding it (removes additional params)
    case Video.parse_url(url) do
      {provider, id} ->
        case HTTPoison.get(Video.build_url(%{provider: provider, provider_id: id})) do
          {:ok, %HTTPoison.Response{body: body}} ->
            meta = Floki.attribute(body, "meta[property='og:title']", "content")
            case meta do
              [] -> {:error, "Page does not contains an OpenGraph title attribute"}
              [title] -> {:ok, HtmlEntities.decode(title)}
            end
          {_, _} -> {:error, "Remote URL didn't respond correctly"}
        end
      nil -> {:error, "Invalid URL"}
    end


    if Video.is_valid_url(url) do
      # Clean the url by parsing then rebuilding it (removes additional params)
      {provider, id} = Video.parse_url(url)
      case HTTPoison.get(Video.build_url(%{provider: provider, provider_id: id})) do
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
