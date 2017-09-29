defmodule CaptainFact.Videos do
  @moduledoc """
  The boundary for the Videos system.
  """

  import Ecto.Query, warn: false
  import CaptainFact.Videos.MetadataFetcher

  alias CaptainFact.Repo
  alias CaptainFact.Accounts.UserPermissions
  alias CaptainFactWeb.Video


  @doc"""
  List videos
  `lang_filter` can be provided as a two-letters locale (fr,de,en...etc). The special value "unknown" will list all
  the videos for which locale is unknown
  """
  def videos_list(lang_filter), do: Repo.all(videos_query(lang_filter))
  def videos_list(), do: Repo.all(videos_query())

  @doc"""
  Return the corresponding video if it has already been added, `nil` otherwise
  """
  def get_video_by_url(url) do
    case Video.parse_url(url) do
      {provider, id} -> Repo.get_by(Video.with_speakers(Video), provider: provider, provider_id: id)
      nil -> nil
    end
  end

  @doc"""
  Add a new video.
  Returns video if success or {:error, reason} if something bad append. Can also throw if bad permissions
  """
  def create!(user, video_url) do
    # Unsafe check before request just to ensure user is not using this method to DDOS youtube
    UserPermissions.check!(user, :add_video)

    case fetch_video_metadata(video_url) do
      {:ok, metadata} ->
        changeset = Video.changeset(%Video{}, metadata)
        user
        |> UserPermissions.lock!(:add_video, fn _ -> Repo.insert!(changeset) end)
        |> Map.put(:speakers, [])
      error -> error
    end
  end

  defp videos_query("unknown"), do: where(videos_query(), [v], is_nil(v.language))
  defp videos_query(language), do: where(videos_query(), [v], language: ^language)
  defp videos_query() do
    Video
    |> Video.with_speakers
    |> order_by([v], desc: v.id)
  end
end