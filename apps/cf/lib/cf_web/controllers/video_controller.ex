defmodule CF.Web.VideoController do
  @moduledoc """
  Controller for all requests on `/videos`
  """

  use CF.Web, :controller
  import CF.Videos

  action_fallback(CF.Web.FallbackController)

  @doc """
  List all videos. Accept `filters` to be passed as parameters.

  Valid filters:

    - language
    - is_partner
    - speaker: can be the speaker slug or its integer ID
  """
  def index(conn, filters) when not is_nil(filters),
    do: render(conn, :index, videos: videos_list(prepare_filters(filters)))

  def index(conn, _params),
    do: render(conn, :index, videos: videos_list())

  @doc """
  List all videos but only return indexes.
  """
  @deprecated "Extension/Injector is now using GraphQL API for this"
  def index_ids(conn, %{"min_id" => min_id}),
    do: json(conn, videos_index(min_id))

  def index_ids(conn, _),
    do: json(conn, videos_index())

  @doc """
  Create a new video based on `url`.
  If it already exist, just returns the video.
  """
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

  @doc """
  Get a video by its URL
  """
  def search(conn, %{"url" => url}) do
    case get_video_by_url(url) do
      nil -> send_resp(conn, 204, "")
      video -> render(conn, "show.json", video: video)
    end
  end

  defp prepare_filters(filters) do
    filters
    |> Enum.map(&prepare_filter/1)
    |> Enum.filter(&(&1 != nil))
  end

  # ---- Private ----

  # Map a filter as received in GET params to one Videos can understand
  defp prepare_filter({"speaker", value}) do
    case Integer.parse(value) do
      {id, ""} ->
        # It's an ID (string has only number)
        {:speaker_id, id}

      _ ->
        # It's a slug (string has at least one alpha character)
        {:speaker_slug, value}
    end
  end

  defp prepare_filter({"language", value}),
    do: {:language, value}

  defp prepare_filter({"is_partner", value}) do
    # Accept both bool and string values to handle GET params and test values
    cond do
      value in ["true", true] -> {:is_partner, true}
      value in ["false", false] -> {:is_partner, false}
      true -> nil
    end
  end

  defp prepare_filter(_),
    do: nil
end
