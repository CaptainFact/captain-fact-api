defmodule CaptainFactWeb.SpeakerView do
  use CaptainFactWeb, :view

  def render("show.json", %{speaker: speaker}) do
    render_one(speaker, CaptainFactWeb.SpeakerView, "speaker.json")
  end

  def render("speaker.json", %{speaker: speaker}) do
    %{
      id: speaker.id,
      slug: speaker.slug,
      full_name: speaker.full_name,
      title: speaker.title,
      picture: CaptainFact.Speakers.Picture.url({speaker.picture, speaker}, :thumb),
      is_user_defined: speaker.is_user_defined,
      country: speaker.country,
      wikidata_item_id: speaker.wikidata_item_id
    }
  end
end
