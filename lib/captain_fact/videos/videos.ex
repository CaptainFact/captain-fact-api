defmodule CaptainFact.Videos do
  @moduledoc """
  The boundary for the Videos system.
  """

  import Ecto.Query, warn: false
  import CaptainFact.Videos.MetadataFetcher

  alias Ecto.Multi
  alias CaptainFact.Repo
  alias CaptainFact.Actions.Recorder
  alias CaptainFact.Accounts.UserPermissions
  alias CaptainFact.Speakers.{Statement, Speaker, VideoSpeaker}
  alias CaptainFact.Videos.Video



  def data(), do: Dataloader.Ecto.new(Repo, query: &query/2)
  def query(Video, filters), do: videos_query(Video, filters)
  def query(Statement = query, _), do: from(s in query, where: s.is_removed == false)
  def query(queryable, _), do: queryable

  @doc"""
  List videos. `filters` may contain the following entries:
    * language: two characters identifier string (fr,en,es...etc) or "unknown" to list videos with unknown language
  """
  def videos_list(filters \\ []), do: Repo.all(videos_query(Video.with_speakers(Video), filters))

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
      {provider, id} -> Repo.get_by(Video.with_speakers(Video), provider: provider, provider_id: id)
      nil -> nil
    end
  end

  def get_video_by_id(id), do: Repo.get(Video, id)

  @doc"""
  Add a new video.
  Returns video if success or {:error, reason} if something bad append. Can also throw if bad permissions
  """
  def create!(user, video_url) do
    UserPermissions.check!(user, :add, :video)
    case fetch_video_metadata(video_url) do
      {:ok, metadata} ->
        video =
          Video.changeset(%Video{}, metadata)
          |> Repo.insert!()
          |> Map.put(:speakers, [])
        Recorder.record!(user, :add, :video, %{entity_id: video.id})
        video
      error -> error
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
    |> Recorder.multi_record(user, :update, :video, %{entity_id: video_id, changes: %{"statements_time" => offset}})
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
    Repo.all(from(
      s in Speaker,
      join: vs in VideoSpeaker, on: vs.speaker_id == s.id,
      where: vs.video_id in ^videos_ids,
      select: {vs.video_id, s}
    )) |> Enum.group_by(&(elem(&1, 0)), &(elem(&1, 1)))
  end

  defp videos_query(query, filters) do
    query
    |> order_by([v], desc: v.id)
    |> filter_with(filters)
  end

  defp filter_with(query, filters) do
    Enum.reduce(filters, query, fn
      {:language, "unknown"}, query ->
        from v in query, where: is_nil(v.language)
      {:language, language}, query ->
        from v in query, where: v.language == ^language
      {:speaker_id, id}, query ->
        from v in query, join: s in assoc(v, :speakers), where: s.id == ^id
      {:speaker_slug, slug}, query ->
        from v in query, join: s in assoc(v, :speakers), where: s.slug == ^slug
      {:min_id, id}, query ->
        from v in query, where: v.id > ^id
    end)
  end
end