defmodule CaptainFact.Speakers do
  @moduledoc"""
  Speakers utils
  """

  alias CaptainFact.Repo
  alias CaptainFact.Speakers.Picture


  @doc"""
  Fetch speaker's picture, overriding the existing picture if there's one
  Returns {:ok, speaker} if success, {:error, reason} otherwise
  """
  def fetch_picture(speaker, picture_url) do
    case Picture.store({picture_url, speaker}) do
      {:ok, picture} ->
        speaker
        |> Ecto.Changeset.change(picture: %{file_name: picture, updated_at: Ecto.DateTime.utc})
        |> Repo.update()
      error -> error
    end
  end
end