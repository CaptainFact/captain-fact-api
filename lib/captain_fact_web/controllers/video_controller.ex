defmodule CaptainFactWeb.VideoController do
  use CaptainFactWeb, :controller
  import CaptainFact.Videos

  action_fallback CaptainFactWeb.FallbackController


  @accepted_filters %{
    "language" => :language,
    "speaker" => :speaker
  }

  def index(conn, filters) when not is_nil(filters),
    do: render(conn, :index, videos: videos_list(prepare_filters(filters)))
  def index(conn, _params),
    do: render(conn, :index, videos: videos_list())

  def index_ids(conn, %{"min_id" => min_id}),
    do: json(conn, videos_index(min_id))

  def get_or_create(conn, %{"url" => url}) do
    case get_video_by_url(url) do
      nil ->
        Guardian.Plug.current_resource(conn)
        |> create!(url)
        |> case do
             {:error, message} -> json(put_status(conn, :unprocessable_entity), %{error: %{url: message}})
             video -> render(conn, "show.json", video: video)
           end
      video ->
        render(conn, "show.json", video: video)
    end
  end

  def search(conn, %{"url" => url}) do
    case get_video_by_url(url) do
      nil -> send_resp(conn, 204, "")
      video -> render(conn, "show.json", video: video)
    end
  end

  defp prepare_filters(filters) do
    filters_list = Enum.map(filters, fn {key, value} -> {Map.get(@accepted_filters, key), value} end)
    if Keyword.has_key?(filters_list, :speaker) do
      Keyword.update!(filters_list, :speaker, fn slug_or_id ->
        case Integer.parse(slug_or_id) do
          {id, ""} -> id # It's an ID (string has only number)
          _ -> slug_or_id # It's a slug (string has at least one alpha character)
        end
      end)
    else
      filters_list
    end
  end
end
