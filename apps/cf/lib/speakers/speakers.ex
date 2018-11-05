defmodule CF.Speakers do
  @moduledoc """
  Speakers utils
  """

  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.Speaker
  alias DB.Type.SpeakerPicture

  @doc """
  Fetch speaker's picture, overriding the existing picture if there's one
  Returns {:ok, speaker} if success, {:error, reason} otherwise
  """
  def fetch_picture(speaker, picture_url) do
    case SpeakerPicture.store({picture_url, speaker}) do
      {:ok, picture} ->
        speaker
        |> Ecto.Changeset.change(picture: %{file_name: picture, updated_at: DateTime.utc_now()})
        |> Repo.update()

      error ->
        error
    end
  end

  @doc """
  Generate slug or update existing one for `speaker`
  """
  def generate_slug(speaker = %Speaker{}) do
    speaker
    |> Speaker.changeset_generate_slug()
    |> Repo.update()
  end

  @doc """
  Generate slugs for all speakers without one
  """
  def generate_all_slugs() do
    Speaker
    |> where([s], is_nil(s.slug))
    |> Repo.all()
    |> Enum.map(&generate_slug/1)
  end
end
