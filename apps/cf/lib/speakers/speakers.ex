defmodule CF.Speakers do
  @moduledoc """
  Speakers utils
  """

  require Logger
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.Speaker
  alias DB.Schema.VideoSpeaker
  alias DB.Type.SpeakerPicture

  @doc """
  Fetch speaker's picture, overriding the existing picture if there's one
  Returns {:ok, speaker} if success, {:error, reason} otherwise
  """
  def fetch_picture(speaker, picture_url) do
    case SpeakerPicture.store({picture_url, speaker}) do
      {:ok, picture} ->
        speaker
        |> Ecto.Changeset.change(
          picture: %{
            file_name: picture,
            updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          }
        )
        |> Repo.update()

      error ->
        error
    end
  end

  @doc """
  Calls `fetch_picture/2` with the picture retrieved from wikidata using
  `retrieve_wikimedia_picture_url/1`
  """
  def fetch_picture_from_wikimedia(_speaker = %Speaker{wikidata_item_id: nil}) do
    {:error, "Cannot fetch picture from wikimedia if wikidata_item_id is no set"}
  end

  def fetch_picture_from_wikimedia(speaker) do
    case retrieve_wikimedia_picture_url(speaker) do
      {:error, reason} ->
        {:error, reason}

      {:ok, url} ->
        fetch_picture(speaker, url)
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

  def retrieve_wikimedia_picture_url(%Speaker{wikidata_item_id: nil}) do
    nil
  end

  def retrieve_wikimedia_picture_url(speaker = %Speaker{wikidata_item_id: qid}) do
    wikidata_url =
      "https://www.wikidata.org/w/api.php?action=wbgetclaims&entity=#{qid}&property=P18&format=json"

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(wikidata_url),
         {:ok, decoded_response} <- Poison.decode(body),
         filename when not is_nil(filename) <- picture_filename_from_response(decoded_response) do
      {:ok, wikimedia_url_from_filename(filename)}
    else
      {:error, error = %HTTPoison.Error{}} ->
        Logger.warn("Wikidata query failed: #{error.reason}")
        {:error, "Connection failed"}

      _e ->
        Logger.info("No picture found for #{speaker.full_name}")
        {:error, "No picture found"}
    end
  end

  def merge_speakers(speaker_from, speaker_into) do
    Ecto.Multi.new()
    # Update speaker profile
    |> Ecto.Multi.run(:speaker_into, fn _repo, _ ->
      speaker_into
      |> Speaker.changeset(merge_speakers_fields(speaker_from, speaker_into))
      |> Repo.update()
    end)
    # Update VideoSpeakers
    |> Ecto.Multi.update_all(:videos_speakers, speaker_videos(speaker_from),
      set: [speaker_id: speaker_into.id]
    )
    # Update statements
    |> Ecto.Multi.update_all(:statements, speaker_statements(speaker_from),
      set: [speaker_id: speaker_into.id]
    )
    # Update user profiles
    |> Ecto.Multi.update_all(:users, speaker_users(speaker_from),
      set: [speaker_id: speaker_into.id]
    )
    # Mark first speaker as deleted
    |> Ecto.Multi.delete(:speaker_from, speaker_from)
    |> DB.Repo.transaction()
  end

  defp merge_speakers_fields(speaker_from, speaker_into) do
    speaker_from
    |> Map.from_struct()
    |> Map.merge(remove_nil_values_from_struct(speaker_into))
    |> Map.take([:full_name, :title, :country, :wikidata_item_id])
    |> Enum.into(%{})
  end

  defp speaker_videos(speaker) do
    from(v in VideoSpeaker, where: v.speaker_id == ^speaker.id)
  end

  defp speaker_statements(speaker) do
    from(s in DB.Schema.Statement, where: s.speaker_id == ^speaker.id)
  end

  defp speaker_users(speaker) do
    from(u in DB.Schema.User, where: u.speaker_id == ^speaker.id)
  end

  defp remove_nil_values_from_struct(struct) do
    struct
    |> Map.from_struct()
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
  end

  defp picture_filename_from_response(%{"claims" => %{"P18" => images}}) do
    case images do
      [%{"mainsnak" => %{"datavalue" => %{"value" => filename}}}] ->
        filename

      [%{"mainsnak" => %{"datavalue" => %{"value" => filename}}} | _] ->
        Logger.debug("Multiple pictures available: #{inspect(images)}")
        filename
    end
  end

  defp picture_filename_from_response(_), do: nil

  defp wikimedia_url_from_filename(filename) do
    formatted_filename = String.replace(filename, " ", "_")
    hash = Base.encode16(:crypto.hash(:md5, formatted_filename), case: :lower)
    hash_1 = String.at(hash, 0)
    hash_2 = String.at(hash, 1)
    path = "#{hash_1}/#{hash_1}#{hash_2}/#{formatted_filename}"
    "https://upload.wikimedia.org/wikipedia/commons/#{path}"
  end
end
