defmodule CF.Graphql.Resolvers.Videos do
  @moduledoc """
  Resolver for `DB.Schema.Video`
  """

  alias Kaur.Result

  import Ecto.Query
  import Absinthe.Resolution.Helpers, only: [batch: 3]

  alias DB.Repo
  alias DB.Schema.Video
  alias DB.Schema.Statement

  # Queries

  def get(_root, %{id: id}, _info) do
    case CF.Videos.get_video_by_id(id) do
      nil -> {:error, "Video #{id} doesn't exist"}
      video -> {:ok, video}
    end
  end

  def get(_root, %{hash_id: id}, _info) do
    case CF.Videos.get_video_by_id(id) do
      nil -> {:error, "Video #{id} doesn't exist"}
      video -> {:ok, video}
    end
  end

  def get(_root, %{url: url}, _info) do
    case CF.Videos.get_video_by_url(url) do
      nil -> {:error, "Video with url #{url} doesn't exist"}
      video -> {:ok, video}
    end
  end

  @deprecated "Use paginated_list/3"
  def list(_root, args, _info) do
    Video
    |> Video.query_list(Map.get(args, :filters, []), args[:limit])
    |> Repo.all()
    |> Result.ok()
  end

  def paginated_list(_root, args = %{offset: offset, limit: limit}, _info) do
    Video
    |> Video.query_list(Map.get(args, :filters, []))
    |> Repo.paginate(page: offset, page_size: limit)
    |> Result.ok()
  end

  # Fields

  def url(video, _, _) do
    {:ok, DB.Schema.Video.build_url(video)}
  end

  def statements(video, _, _) do
    batch({__MODULE__, :fetch_statements_by_videos_ids}, video.id, fn results ->
      {:ok, Map.get(results, video.id) || []}
    end)
  end

  def fetch_statements_by_videos_ids(_, videos_ids) do
    Statement
    |> where([s], s.video_id in ^videos_ids)
    |> where([s], s.is_removed == false)
    |> Repo.all()
    |> Enum.group_by(& &1.video_id)
  end
end
