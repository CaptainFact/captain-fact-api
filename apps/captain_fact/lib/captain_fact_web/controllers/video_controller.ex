defmodule CaptainFactWeb.VideoController do
  use CaptainFactWeb, :controller
  import CaptainFact.Videos

  action_fallback CaptainFactWeb.FallbackController


  @accepted_filters %{
    "language" => :language,
    "speaker" => :speaker,
    "is_partner" => :is_partner
  }

  def index(conn, filters) when not is_nil(filters),
    do: render(conn, :index, videos: videos_list(prepare_filters(filters)))
  def index(conn, _params),
    do: render(conn, :index, videos: videos_list())

  def index_ids(conn, %{"min_id" => min_id}),
    do: json(conn, videos_index(min_id))
  def index_ids(conn, _),
    do: json(conn, videos_index())

  def get_or_create(conn, params = %{"url" => url}) do
    case get_video_by_url(url) do
      nil ->
        conn
        |> Guardian.Plug.current_resource()
        |> create!(url, params["is_partner"])
        |> case do
             {:error, message} ->
               conn
               |> put_status(:unprocessable_entity)
               |> json(%{error: %{url: message}})
             {:ok, video} ->
               render(conn, "show.json", video: video)
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
    filters_list = Enum.map(filters, fn {key, value} ->
      {Map.get(@accepted_filters, key), value}
    end)

    if Keyword.has_key?(filters_list, :speaker) do
      speaker_identifier = Keyword.get(filters_list, :speaker)
      updated_filters =
        case Integer.parse(speaker_identifier) do
          {id, ""} ->
            # It's an ID (string has only number)
            Keyword.put(filters_list, :speaker_id, id)
          _ ->
            # It's a slug (string has at least one alpha character)
            Keyword.put(filters_list, :speaker_slug, speaker_identifier)
        end

      Keyword.delete(updated_filters, :speaker)
    else
      filters_list
    end
  end
end
