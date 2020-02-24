defmodule CF.Videos do
  @moduledoc """
  The boundary for the Videos system.
  """

  import Ecto.Query, warn: false
  import CF.Videos.MetadataFetcher
  import CF.Videos.CaptionsFetcher
  import CF.Actions.ActionCreator, only: [action_update: 2]

  alias Ecto.Multi
  alias DB.Repo
  alias DB.Schema.Video
  alias DB.Schema.Speaker
  alias DB.Schema.VideoSpeaker
  alias DB.Schema.VideoCaption

  alias CF.Actions.ActionCreator
  alias CF.Accounts.UserPermissions
  alias CF.Videos.MetadataFetcher

  @captions_fetcher Application.get_env(:cf, :captions_fetcher)

  @doc """
  TODO with_speakers param is only required by REST API
  List videos. `filters` may contain the following entries:
    * language: two characters identifier string (fr,en,es...etc) or
                "unknown" to list videos with unknown language
  """
  def videos_list(filters \\ [], with_speakers \\ true)

  def videos_list(filters, true),
    do: Repo.all(Video.query_list(Video.with_speakers(Video), filters))

  def videos_list(filters, false),
    do: Repo.all(Video.query_list(Video, filters))

  @doc """
  Get videos added by given user. This will return all videos, included the ones
  marked as `unlisted`.
  """
  def added_by_user(user, paginate_options \\ []) do
    Video
    |> join(:inner, [v], a in DB.Schema.UserAction, a.video_id == v.id)
    |> where([_, a], a.user_id == ^user.id)
    |> where([_, a], a.type == ^:add and a.entity == ^:video)
    |> DB.Query.order_by_last_inserted_desc()
    |> Repo.paginate(paginate_options)
  end

  @doc """
  Return the corresponding video if it has already been added, `nil` otherwise
  """
  def get_video_by_url(url) do
    case Video.parse_url(url) do
      {:youtube, id} ->
        Video
        |> Video.with_speakers()
        |> Repo.get_by(youtube_id: id)

      {:facebook, id} ->
        Video
        |> Video.with_speakers()
        |> Repo.get_by(facebook_id: id)

      _ ->
        nil
    end
  end

  @doc """
  Get video in database using its integer ID
  """
  def get_video_by_id(id),
    do: Repo.get(Video, id)

  @doc """
  Add a new video.
  Returns video if success or {:error, reason} if something bad append.
  Can also throw if bad permissions.
  """
  def create!(user, video_url, params \\ []) do
    UserPermissions.check!(user, :add, :video)

    with metadata_fetcher when not is_nil(metadata_fetcher) <- get_metadata_fetcher(video_url),
         {:ok, metadata} <- metadata_fetcher.(video_url) do
      # Videos posted by publishers are recorded as partner unless explicitely
      # specified otherwise (false)
      base_video = %Video{
        is_partner: user.is_publisher && Keyword.get(params, :is_partner) != false,
        unlisted: Keyword.get(params, :unlisted, false)
      }

      Multi.new()
      |> Multi.insert(:video_without_hash_id, Video.changeset(base_video, metadata))
      |> Multi.run(:video, fn %{video_without_hash_id: video} ->
        video
        |> Video.changeset_generate_hash_id()
        |> Repo.update()
      end)
      |> Multi.run(:action, fn %{video: video} ->
        Repo.insert(ActionCreator.action_add(user.id, video))
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{video: video}} ->
          # Return created video with empty speakers
          {:ok, Map.put(video, :speakers, [])}

        {:error, _, reason, _} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Shift all video's statements by given offset.
  Returns {:ok, statements} if success, {:error, reason} otherwise.
  Returned statements contains only an id and a key
  """
  def shift_statements(user, video_id, offsets) do
    UserPermissions.check!(user, :update, :video)
    video = Repo.get!(Video, video_id)
    changeset = Video.changeset_shift_offsets(video, offsets)

    Multi.new()
    |> Multi.update(:video, changeset)
    |> Multi.insert(:action_update, action_update(user.id, changeset))
    |> Repo.transaction()
    |> case do
      {:ok, %{video: video}} ->
        {:ok, video}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  @doc """
  Takes as list of video id as `Integer` and returns a map like:
  %{
    video_id_1 => [%Speaker{...}, %Speaker{...}],
    video_id_2 => [%Speaker{...}]
  }
  """
  def videos_speakers(videos_ids) do
    query =
      from(
        s in Speaker,
        join: vs in VideoSpeaker,
        on: vs.speaker_id == s.id,
        where: vs.video_id in ^videos_ids,
        select: {vs.video_id, s}
      )

    Enum.group_by(Repo.all(query), &elem(&1, 0), &elem(&1, 1))
  end

  @doc """
  Download and store captions for a video.
  Returns captions if success or {:error, reason} if something bad happend.

  Usage:
  iex> download_captions(video)
  """
  def download_captions(video = %Video{}) do
    with {:ok, captions} <- @captions_fetcher.fetch(video) do
      captions
      |> VideoCaption.changeset(%{video_id: video.id})
      |> Repo.insert()

      {:ok, captions}
    end
  end

  defp get_metadata_fetcher(video_url) do
    if Application.get_env(:cf, :use_test_video_metadata_fetcher) do
      &MetadataFetcher.Test.fetch_video_metadata/1
    else
      case Video.parse_url(video_url) do
        {:youtube, _} -> &MetadataFetcher.Youtube.fetch_video_metadata/1
        {:facebook, _} -> &MetadataFetcher.Opengraph.fetch_video_metadata/1
        _ -> &MetadataFetcher.Opengraph.fetch_video_metadata/1
      end
    end
  end
end
