defmodule CaptainFactWeb.VideoView do
  use CaptainFactWeb, :view

  def render("index.json", %{videos: videos}) do
    render_many(videos, CaptainFactWeb.VideoView, "video.json")
  end

  def render("show.json", %{video: video}) do
    render_one(video, CaptainFactWeb.VideoView, "video.json")
  end

  def render("video.json", %{video: video}) do
    %{
      id: video.id,
      hash_id: video.hash_id,
      title: video.title,
      provider: video.provider,
      provider_id: video.provider_id,
      url: DB.Schema.Video.build_url(video),
      posted_at: video.inserted_at,
      speakers: render_many(video.speakers, CaptainFactWeb.SpeakerView, "speaker.json"),
      language: video.language,
      is_partner: video.is_partner
    }
  end
end
