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
  alias Ecto.Multi

  alias CF.Accounts.UserPermissions

  import CF.Actions.ActionCreator,
    only: [action_add: 3, action_create: 2, action_remove: 3, action_restore: 3]

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

  @doc """
  Search speakers by name (minimum 3 characters). Caller may enforce stricter rules.
  """
  def search_by_name(query, _limit) when byte_size(query) < 3, do: {:ok, []}

  def search_by_name(query, limit) do
    query_pattern = "%#{escape_like(query)}%"

    speakers_query =
      from(
        s in Speaker,
        where: fragment("unaccent(?) ILIKE unaccent(?)", s.full_name, ^query_pattern),
        group_by: s.id,
        select: %{id: s.id, full_name: s.full_name, slug: s.slug, picture: s.picture},
        limit: ^limit
      )

    {:ok, Repo.all(speakers_query)}
  end

  @doc """
  Adds an existing speaker to a video. Caller must load the speaker.
  """
  def add_speaker_to_video(user_id, video_id, %Speaker{} = speaker)
      when is_integer(user_id) and is_integer(video_id) do
    UserPermissions.check!(user_id, :add, :speaker)

    changeset = VideoSpeaker.changeset(%VideoSpeaker{speaker_id: speaker.id, video_id: video_id})

    Multi.new()
    |> Multi.insert(:video_speaker, changeset)
    |> Multi.insert(:action_add, action_add(user_id, video_id, speaker))
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, speaker}

      {:error, _, %{errors: errors}, _} ->
        if errors[:video] == {"has already been taken", []},
          do: {:error, :speaker_already_on_video},
          else: {:error, :failed_to_add_speaker}
    end
  end

  @doc """
  Creates a new speaker and links them to a video.
  """
  def create_speaker_and_add_to_video(user_id, video_id, full_name)
      when is_integer(user_id) and is_integer(video_id) and is_binary(full_name) do
    UserPermissions.check!(user_id, :create, :speaker)

    speaker_changeset = Speaker.changeset(%Speaker{}, %{full_name: full_name})

    Multi.new()
    |> Multi.insert(:speaker, speaker_changeset)
    |> Multi.run(:video_speaker, fn _repo, %{speaker: speaker} ->
      %VideoSpeaker{speaker_id: speaker.id, video_id: video_id}
      |> VideoSpeaker.changeset()
      |> Repo.insert()
    end)
    |> Multi.run(:action_create, fn _repo, %{speaker: speaker} ->
      Repo.insert(action_create(user_id, speaker))
    end)
    |> Multi.run(:action_add, fn _repo, %{speaker: speaker} ->
      Repo.insert(action_add(user_id, video_id, speaker))
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{speaker: speaker}} ->
        {:ok, speaker}

      {:error, :speaker, _changeset, %{}} ->
        {:error, :invalid_speaker}

      _ ->
        {:error, :failed_to_create_speaker}
    end
  end

  @doc """
  Removes a speaker from a video. Caller must load the speaker.
  """
  def remove_speaker_from_video(user_id, video_id, %Speaker{} = speaker)
      when is_integer(user_id) and is_integer(video_id) do
    UserPermissions.check!(user_id, :remove, :speaker)

    video_speaker = %VideoSpeaker{speaker_id: speaker.id, video_id: video_id}

    Multi.new()
    |> Multi.delete(:video_speaker, VideoSpeaker.changeset(video_speaker))
    |> Multi.insert(:action_remove, action_remove(user_id, video_id, speaker))
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, speaker.id}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  @doc """
  Updates a speaker's attributes.
  """
  def update_speaker(user_id, %Speaker{} = speaker, attrs)
      when is_integer(user_id) and is_map(attrs) do
    UserPermissions.check!(user_id, :update, :speaker)

    speaker
    |> Speaker.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Lists video IDs a speaker is associated with.
  """
  def video_ids_for_speaker(speaker_id) when is_integer(speaker_id) do
    Repo.all(from(vs in VideoSpeaker, where: vs.speaker_id == ^speaker_id, select: vs.video_id))
  end

  @doc """
  Restores a speaker link to a video after removal. Caller must load the speaker.
  """
  def restore_speaker_to_video(user_id, video_id, %Speaker{} = speaker)
      when is_integer(user_id) and is_integer(video_id) do
    UserPermissions.check!(user_id, :restore, :speaker)

    video_speaker = %VideoSpeaker{speaker_id: speaker.id, video_id: video_id}

    Multi.new()
    |> Multi.insert(:video_speaker, VideoSpeaker.changeset(video_speaker))
    |> Multi.insert(:action_restore, action_restore(user_id, video_id, speaker))
    |> Repo.transaction()
    |> case do
      {:ok, %{action_restore: action}} ->
        {:ok, %{speaker: speaker, action: action}}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
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
        Logger.warning("Wikidata query failed: #{error.reason}")
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

  # Escape PostgreSQL LIKE/ILIKE wildcards so user input is treated as literal text.
  # Must be applied before wrapping with the surrounding `%` delimiters.
  defp escape_like(query) do
    query
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
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
