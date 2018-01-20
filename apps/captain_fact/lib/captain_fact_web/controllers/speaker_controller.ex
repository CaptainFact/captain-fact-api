defmodule CaptainFactWeb.SpeakerController do
  use CaptainFactWeb, :controller
  alias DB.Schema.Speaker

  action_fallback CaptainFactWeb.FallbackController


  def show(conn, %{"slug_or_id" => slug_or_id}) do
    speaker = case Integer.parse(slug_or_id) do
      {id, ""} -> Repo.get!(Speaker, id) # It's an ID (string has only number)
      _ -> Repo.get_by!(Speaker, slug: slug_or_id) # It's a slug (string has at least one alpha character)
    end
    render(conn, "show.json", speaker: speaker)
  end
end