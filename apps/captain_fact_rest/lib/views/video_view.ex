defmodule CaptainFactREST.VideoView do
  use CaptainFactREST, :view

  def render("index.json", %{videos: videos}) do
    render_many(videos, CaptainFactREST.VideoView, "video.json")
  end

  def render("show.json", %{video: video}) do
    render_one(video, CaptainFactREST.VideoView, "video.json")
  end

  def render("video.json", %{video: video}) do
    %{
      id: CaptainFact.Videos.VideoHashId.encode(video.id),
      title: video.title,
      provider: video.provider,
      provider_id: video.provider_id,
      url: CaptainFact.Videos.Video.build_url(video),
      posted_at: video.inserted_at,
      speakers: render_many(video.speakers, CaptainFactREST.SpeakerView, "speaker.json"),
      language: video.language
    }
  end
end
