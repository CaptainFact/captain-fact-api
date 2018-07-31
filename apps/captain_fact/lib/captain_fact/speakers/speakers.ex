defmodule CaptainFact.Speakers do
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
  Set given speaker `is_user_defined` field to false which will prevent modifications. Also generates a slug.
  """
  def validate_speaker(speaker) do
    speaker
    |> Speaker.changeset_validate_speaker()
    |> Repo.update()
  end

  @doc """
  Generate slugs for all speakers with `is_user_defined` set to false
  """
  def generate_slugs() do
    Speaker
    |> where([s], s.is_user_defined == false and is_nil(s.slug))
    |> Repo.all()
    |> Enum.map(&Speaker.changeset_validate_speaker/1)
    |> Enum.map(&Repo.update/1)
  end
end
