defmodule CF.Videos do
  @moduledoc """
  The boundary for the Videos system.
  """

  require Logger

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
    |> join(:inner, [v], a in DB.Schema.UserAction, on: a.video_id == v.id)
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

  def get_video_by_hash_id(hash_id),
    do: Repo.get_by(Video, hash_id: hash_id)

  @doc """
  Add a new video.
  Returns video if success or {:error, reason} if something bad append.
  Can also throw if bad permissions.
  """
  def create!(user, video_url, params \\ []) do
    is_unlisted =
      case Keyword.get(params, :unlisted, false) do
        v when v in [nil, false] ->
          UserPermissions.check!(user, :add, :video)
          false

        true ->
          UserPermissions.check!(user, :add, :unlisted_video)
          true
      end

    video_entity = if is_unlisted, do: :unlisted_video, else: :video

    with metadata_fetcher when not is_nil(metadata_fetcher) <- get_metadata_fetcher(video_url),
         {:ok, metadata} <- metadata_fetcher.(video_url) do
      # Videos posted by publishers are recorded as partner unless explicitely
      # specified otherwise (false)
      base_video = %Video{
        is_partner: user.is_publisher && Keyword.get(params, :is_partner) != false,
        unlisted: is_unlisted
      }

      Multi.new()
      |> Multi.insert(:video_without_hash_id, Video.changeset(base_video, metadata))
      |> Multi.run(:video, fn _repo, %{video_without_hash_id: video} ->
        video
        |> Video.changeset_generate_hash_id()
        |> Repo.update()
      end)
      |> Multi.run(:action, fn _repo, %{video: video} ->
        Repo.insert(ActionCreator.action_add(user.id, video_entity, video))
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{video: db_video}} ->
          # Return created video with empty speakers
          video = Map.put(db_video, :speakers, [])
          # Ignore errors if indexing fails
          CF.Algolia.VideosIndex.save_object(video)
          {:ok, video}

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
    video = Repo.get!(Video, video_id)

    case video.unlisted do
      false ->
        UserPermissions.check!(user, :update, :video)

      true ->
        UserPermissions.check!(user, :update, :unlisted_video)
    end

    video_entity = if video.unlisted, do: :unlisted_video, else: :video
    changeset = Video.changeset_shift_offsets(video, offsets)

    Multi.new()
    |> Multi.update(:video, changeset)
    |> Multi.insert(:action_update, ActionCreator.action_update(user.id, video_entity, changeset))
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
  Returns captions if success or {:error, reason} if something bad happened.
  """
  def download_captions(video = %Video{}) do
    # Try to fetch new captions
    existing_captions = get_existing_captions(video)
    captions_base = if existing_captions, do: existing_captions, else: %VideoCaption{}

    case @captions_fetcher.fetch(video) do
      {:ok, captions} ->
        captions_base
        |> VideoCaption.changeset(Map.merge(captions, %{video_id: video.id}))
        |> Repo.insert_or_update()
        |> case do
          # The Atoms become strings when saving/loading from the DB, let's make things consistent
          {:error, changeset} ->
            {:error, changeset}

          {:ok, _video_caption} ->
            video
            |> get_existing_captions()
            |> case do
              nil -> {:error, :not_found}
              existing -> {:ok, existing}
            end
        end

      # If no Youtube caption found, insert a dummy entry in DB to prevent retrying for 30 days
      {:error, :not_found} ->
        unless existing_captions do
          Repo.insert(%DB.Schema.VideoCaption{
            video_id: video.id,
            raw: "",
            parsed: [],
            format: "xml"
          })
        end

        {:error, :not_found}
    end
  end

  defp get_existing_captions(video) do
    VideoCaption
    |> where([vc], vc.video_id == ^video.id)
    |> order_by(desc: :updated_at)
    |> limit(1)
    |> Repo.one()
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
