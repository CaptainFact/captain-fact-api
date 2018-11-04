defmodule CF.Web.SpeakerController do
  use CF.Web, :controller
  alias DB.Schema.Speaker

  action_fallback(CF.Web.FallbackController)

  def show(conn, %{"slug_or_id" => slug_or_id}) do
    case get_speaker(slug_or_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(CF.Web.ErrorView, "404.json")

      speaker ->
        render(conn, "show.json", speaker: speaker)
    end
  end

  defp get_speaker(slug_or_id) do
    case Integer.parse(slug_or_id) do
      # It's an ID (string has only number)
      {id, ""} ->
        Repo.get(Speaker, id)

      # It's a slug (string has at least one alpha character)
      _ ->
        slug_or_id = Slugger.slugify(slug_or_id)
        Repo.get_by(Speaker, slug: slug_or_id)
    end
  end
end
