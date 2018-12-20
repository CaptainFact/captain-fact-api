defmodule CF.AtomFeed.Videos do
  @moduledoc """
  ATOM feed for videos added on the platform
  """

  import Ecto.Query

  alias Atomex.{Feed, Entry}
  alias DB.Schema.Video
  alias CF.Utils.FrontendRouter

  @nb_items_max 50

  @doc """
  Get an RSS feed containing all site's videos in reverse chronological
  order (newest first)
  """
  def feed_all() do
    Video
    |> limit(@nb_items_max)
    |> where([v], v.unlisted == false)
    |> preload(:speakers)
    |> order_by(desc: :inserted_at)
    |> DB.Repo.all()
    |> render_feed()
  end

  @doc """
  Render a feed for given videos list
  """
  def render_feed(videos) do
    FrontendRouter.base_url()
    |> Feed.new(last_update(videos), "[CaptainFact] All Videos")
    |> CF.AtomFeed.Common.feed_author()
    |> Feed.link("#{FrontendRouter.base_url()}videos/", rel: "self")
    |> Feed.entries(Enum.map(videos, &render_entry/1))
    |> Feed.build()
    |> Atomex.generate_document()
  end

  defp render_entry(video) do
    video_link = FrontendRouter.video_url(video.hash_id)

    video_link
    |> Entry.new(video.inserted_at, video.title)
    |> Entry.link(video_link)
    |> Entry.published(video.inserted_at)
    |> Entry.content(entry_content(video))
    |> Entry.build()
  end

  defp entry_content(%{speakers: []}) do
    ""
  end

  defp entry_content(video) do
    Enum.map_join(video.speakers, ", ", &render_speaker/1)
  end

  defp render_speaker(speaker = %{full_name: name}),
    do: "[#{name}](#{FrontendRouter.speaker_url(speaker)})"

  defp last_update([video | _]),
    do: video.inserted_at

  defp last_update(_),
    do: DateTime.utc_now()
end
