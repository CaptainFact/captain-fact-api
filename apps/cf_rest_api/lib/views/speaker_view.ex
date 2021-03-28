defmodule CF.RestApi.SpeakerView do
  use CF.RestApi, :view

  def render("show.json", %{speaker: speaker}) do
    render_one(speaker, CF.RestApi.SpeakerView, "speaker.json")
  end

  def render("speaker.json", %{speaker: speaker}) do
    %{
      id: speaker.id,
      slug: speaker.slug,
      full_name: speaker.full_name,
      title: speaker.title,
      picture: DB.Type.SpeakerPicture.full_url(speaker, :thumb),
      country: speaker.country,
      wikidata_item_id: speaker.wikidata_item_id
    }
  end
end
