defmodule CaptainFact.VideoView do
  use CaptainFact.Web, :view

  def render("index.json", %{videos: videos}) do
    render_many(videos, CaptainFact.VideoView, "video.json")
  end

  def render("show.json", %{video: video}) do
    render_one(video, CaptainFact.VideoView, "video.json")
  end

  def render("video.json", %{video: video}) do
    %{id: video.id,
      url: video.url,
      title: video.title,
      isPrivate: video.is_private,
      owner_id: video.owner_id,
      speakers: render_many(video.speakers, CaptainFact.SpeakerView, "speaker.json")
    }
  end

  def render("video_with_statements.json", %{video: video}) do
    %{
      id: video.id,
      url: video.url,
      title: video.title,
      isPrivate: video.is_private,
      owner_id: video.owner_id,
      speakers: render_many(video.speakers, CaptainFact.SpeakerView, "speaker.json"),
      statements: render_many(video.statements, CaptainFact.StatementView, "statement.json")
    }
  end
end
