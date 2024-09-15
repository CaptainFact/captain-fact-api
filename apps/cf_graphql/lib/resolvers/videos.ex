defmodule CF.Graphql.Resolvers.Videos do
  @moduledoc """
  Resolver for `DB.Schema.Video`
  """

  alias Kaur.Result

  import Ecto.Query
  import Absinthe.Resolution.Helpers, only: [batch: 3]

  alias DB.Repo
  alias DB.Schema.Video
  alias DB.Schema.VideoCaption
  alias DB.Schema.Statement

  # Queries

  def get(_root, %{id: id}, _info) do
    case CF.Videos.get_video_by_id(id) do
      nil -> {:error, "Video #{id} doesn't exist"}
      video -> {:ok, video}
    end
  end

  def get(_root, %{hash_id: id}, _info) do
    case CF.Videos.get_video_by_hash_id(id) do
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

  def thumbnail(video, _, _) do
    {:ok, DB.Schema.Video.image_url(video)}
  end

  def statements(video, _, _) do
    batch({__MODULE__, :fetch_statements_by_videos_ids}, video.id, fn results ->
      {:ok, Map.get(results, video.id) || []}
    end)
  end

  def captions(video, _, _) do
    batch({__MODULE__, :fetch_captions_by_video_ids}, video.id, fn results ->
      {:ok,
       case Map.get(results, video.id) do
         captions when is_list(captions) ->
           captions
           |> List.first()
           |> Map.get(:parsed)
           |> Enum.map(&CF.Utils.map_string_keys_to_atom_keys/1)

         nil ->
           nil
       end}
    end)
  end

  def fetch_statements_by_videos_ids(_, videos_ids) do
    Statement
    |> where([s], s.video_id in ^videos_ids)
    |> where([s], s.is_removed == false)
    |> order_by(asc: :time)
    |> Repo.all()
    |> Enum.group_by(& &1.video_id)
  end

  def fetch_captions_by_video_ids(_, video_ids) do
    VideoCaption
    |> where([c], c.video_id in ^video_ids)
    |> order_by(desc: :updated_at)
    |> Repo.all()
    |> Enum.group_by(& &1.video_id)
  end

  def start_automatic_statements_extraction(_root, %{video_id: video_id}, %{
        context: %{user: user}
      }) do
    video = DB.Repo.get!(DB.Schema.Video, video_id)

    # Record a `UserAction`
    user.id
    |> CF.Actions.ActionCreator.action_start_automatic_statements_extraction(video.id)
    |> DB.Repo.insert!()

    # Start the extraction process
    CF.LLMs.StatementsCreator.process_video!(video.id)
    {:ok, video}
  end
end
