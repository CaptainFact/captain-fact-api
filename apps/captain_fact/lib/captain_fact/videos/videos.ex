defmodule CaptainFact.Videos do
  @moduledoc """
  The boundary for the Videos system.
  """

  import Ecto.Query, warn: false
  import CaptainFact.Videos.MetadataFetcher

  alias Ecto.Multi
  alias DB.Repo
  alias DB.Schema.Video
  alias DB.Schema.UserAction
  alias DB.Schema.Statement
  alias DB.Schema.Speaker
  alias DB.Schema.VideoSpeaker

  alias CaptainFact.Actions.Recorder
  alias CaptainFact.Accounts.UserPermissions


  @doc"""
  TODO with_speakers param is only required by REST API
  List videos. `filters` may contain the following entries:
    * language: two characters identifier string (fr,en,es...etc) or "unknown" to list videos with unknown language
  """
  def videos_list(filters \\ [], with_speakers \\ true)
  def videos_list(filters, true),
    do: Repo.all(Video.query_list(Video.with_speakers(Video), filters))
  def videos_list(filters, false),
    do: Repo.all(Video.query_list(Video, filters))

  @doc"""
  Index videos, returning only their id, provider_id and provider.
  Accepted filters are the same than for `videos_list/1`
  """
  def videos_index(from_id \\ 0) do
    Video
    |> select([v], %{id: v.id, provider: v.provider, provider_id: v.provider_id})
    |> where([v], v.id > ^from_id)
    |> Repo.all()
  end


  @doc"""
  Return the corresponding video if it has already been added, `nil` otherwise
  """
  def get_video_by_url(url) do
    case Video.parse_url(url) do
      {provider, id} ->
        Video
        |> Video.with_speakers()
        |> Repo.get_by(provider: provider, provider_id: id)
      nil ->
        nil
    end
  end

  @doc"""
  Get video in database using its integer ID
  """
  def get_video_by_id(id),
    do: Repo.get(Video, id)

  @doc"""
  Add a new video.
  Returns video if success or {:error, reason} if something bad append.
  Can also throw if bad permissions.
  """
  def create!(user, video_url, is_partner \\ nil) do
    UserPermissions.check!(user, :add, :video)
    with {:ok, metadata} <- fetch_video_metadata(video_url) do
      # Videos posted by publishers are recorded as partner unless explicitely
      # specified otherwise (false)
      base_video = %Video{is_partner: user.is_publisher && is_partner != false}

      Multi.new
      |> Multi.insert(:video, Video.changeset(base_video, metadata))
      |> Multi.run(:action, fn %{video: video} ->
           Recorder.record(user, :add, :video, %{
             entity_id: video.id,
             context: UserAction.video_debate_context(video),
             changes: %{"url" => Video.build_url(video)}
           })
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

  @doc"""
  Shift all video's statements by given offset.
  Returns {:ok, statements} if success, {:error, reason} otherwise. Returned statements contains only an id and a key
  """
  def shift_statements(user, video_id, offset) when is_integer(offset) do
    UserPermissions.check!(user, :update, :video)
    statements_query = where(Statement, [s], s.video_id == ^video_id)
    Multi.new
    |> Multi.update_all(:statements_update, statements_query, [inc: [time: offset]], returning: [:id, :time])
    |> Recorder.multi_record(user, :update, :video, %{
      entity_id: video_id,
      changes: %{"statements_time" => offset},
      context: UserAction.video_debate_context(video_id)
    })
    |> Repo.transaction()
    |> case do
         {:ok, %{statements_update: {_, statements}}} -> {:ok, Enum.map(statements, &(%{id: &1.id, time: &1.time}))}
         {:error, _, reason, _} -> {:error, reason}
       end
  end

  @doc"""
  Takes as list of video id as `Integer` and returns a map like:
  %{
    video_id_1 => [%Speaker{...}, %Speaker{...}],
    video_id_2 => [%Speaker{...}]
  }
  """
  def videos_speakers(videos_ids) do
    query = from(
      s in Speaker,
      join: vs in VideoSpeaker, on: vs.speaker_id == s.id,
      where: vs.video_id in ^videos_ids,
      select: {vs.video_id, s}
    )

    Enum.group_by(Repo.all(query), &(elem(&1, 0)), &(elem(&1, 1)))
  end
end