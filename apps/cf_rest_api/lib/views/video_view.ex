defmodule CF.RestApi.VideoView do
  use CF.RestApi, :view

  def render("index.json", %{videos: videos}) do
    render_many(videos, CF.RestApi.VideoView, "video.json")
  end

  def render("show.json", %{video: video}) do
    render_one(video, CF.RestApi.VideoView, "video.json")
  end

  def render("video.json", %{video: video}) do
    %{
      id: video.id,
      hash_id: video.hash_id,
      title: video.title,
      provider: "youtube",
      provider_id: video.youtube_id,
      youtube_id: video.youtube_id,
      youtube_offset: video.youtube_offset,
      url: DB.Schema.Video.build_url(video),
      posted_at: video.inserted_at,
      speakers: render_many(video.speakers, CF.RestApi.SpeakerView, "speaker.json"),
      language: video.language,
      is_partner: video.is_partner,
      unlisted: video.unlisted
    }
  end

  def render("video_with_subscription.json", %{video: video, is_subscribed: is_subscribed}) do
    %{
      id: video.id,
      hash_id: video.hash_id,
      title: video.title,
      provider: "youtube",
      provider_id: video.youtube_id,
      youtube_id: video.youtube_id,
      youtube_offset: video.youtube_offset,
      url: DB.Schema.Video.build_url(video),
      posted_at: video.inserted_at,
      speakers: render_many(video.speakers, CF.RestApi.SpeakerView, "speaker.json"),
      language: video.language,
      is_partner: video.is_partner,
      is_subscribed: is_subscribed
    }
  end
end
