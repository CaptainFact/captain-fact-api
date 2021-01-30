defmodule CF.Graphql.Resolvers.Statements do
  @moduledoc """
  Resolver for `DB.Schema.Statement`
  """

  alias Kaur.Result

  import Ecto.Query
  import Absinthe.Resolution.Helpers, only: [batch: 3]

  alias DB.Repo
  alias DB.Schema.Statement

  # Queries

  def paginated_list(_root, args = %{offset: offset, limit: limit}, _info) do
    # Statement
    # |> order_by(asc: :time)
    #
    # |> Video.query_list(Map.get(args, :filters, []))
    #
    # |> Repo.paginate(page: offset, page_size: limit)
    # |> Result.ok()
    {:ok, nil}
  end

  # Fields

  # def url(video, _, _) do
  #   {:ok, DB.Schema.Video.build_url(video)}
  # end
  #
  # def thumbnail(video, _, _) do
  #   {:ok, DB.Schema.Video.image_url(video)}
  # end
  #
  # def statements(video, _, _) do
  #   batch({__MODULE__, :fetch_statements_by_videos_ids}, video.id, fn results ->
  #     {:ok, Map.get(results, video.id) || []}
  #   end)
  # end
  #
  # def fetch_statements_by_videos_ids(_, videos_ids) do
  #   Statement
  #   |> where([s], s.video_id in ^videos_ids)
  #   |> where([s], s.is_removed == false)
  #   |> order_by(asc: :time)
  #   |> Repo.all()
  #   |> Enum.group_by(& &1.video_id)
  # end
end
