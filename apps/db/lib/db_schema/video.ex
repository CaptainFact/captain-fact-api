defmodule DB.Schema.Video do
  @moduledoc """
  Ecto schema for `videos` table.
  """

  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias DB.Type.VideoHashId
  alias DB.Schema.{Speaker, Statement, VideoSpeaker}

  schema "videos" do
    field(:title, :string)
    field(:hash_id, :string)
    field(:url, :string, virtual: true)
    field(:language, :string, null: true)
    field(:unlisted, :boolean, null: false)
    field(:is_partner, :boolean, null: false)
    field(:thumbnail, :string, null: true)

    # YouTube
    field(:youtube_id, :string)
    field(:youtube_offset, :integer, null: false, default: 0)

    # Facebook
    field(:facebook_id, :string)
    field(:facebook_offset, :integer, null: false, default: 0)

    many_to_many(:speakers, Speaker, join_through: VideoSpeaker, on_delete: :delete_all)
    has_many(:statements, Statement, on_delete: :delete_all)

    timestamps(type: :utc_datetime)
  end

  # Define valid providers

  @providers_regexs %{
    # Map a provider name to its regex, using named_captures to get the id ---------↘️
    youtube:
      ~r/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)(?<id>[^"&?\/ ]{11})/i,
    facebook:
      ~r/(?:https?:\/\/)?(?:www.|web.|m.)?facebook.com\/(?:video.php\?v=(?<id3>\d+)|\?v=(?<id4>)\d+)|\S+\/videos\/((\S+)\/(?<id>\d+)|(?<id2>\d+))\/?/i
  }

  # Define queries

  @doc """
  Select all videos not unlisted and order them by id.

  ## Params

    * query: an Ecto query
    * filters: a list of tuples like {filter_name, value}.
      Valid filters:
        - language: `unknwown` or locale (`fr`, `en`...)
        - speaker_id: speaker's integer ID
        - speaker_slug: speaker's slug
        - min_id: select all videos with id above given integer
    * limit: Max number of videos to return
  """
  def query_list(query, filters \\ [], limit \\ nil) do
    query
    |> where([v], v.unlisted == false)
    |> order_by([v], desc: v.id)
    |> filter_with(filters)
    |> limit_video_query_list(limit)
  end

  defp limit_video_query_list(query, nil),
    do: query

  defp limit_video_query_list(query, limit),
    do: limit(query, ^limit)

  @doc """
  Preload speakers for given video query
  """
  def with_speakers(query) do
    from(v in query, preload: [:speakers])
  end

  @doc """
  Preload statements for given video query
  """
  def with_statements(query) do
    from(v in query, preload: [:statements])
  end

  # Utils

  @doc """
  Check if `url` is a valid URL, with a known provider and a valid ID.

  ## Examples

      iex> DB.Schema.Video.is_valid_url "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
      true
      iex> DB.Schema.Video.is_valid_url "https://www.youtube.com/watch?v="
      false
      iex> DB.Schema.Video.is_valid_url "https://www.google.fr/watch?v=dQw4w9WgXcQ"
      false
  """
  def is_valid_url(url) do
    Enum.find_value(@providers_regexs, false, fn {_, regex} ->
      Regex.match?(regex, url)
    end)
  end

  @doc """
  Build an URL for given video.

  ## Examples

      iex> import DB.Schema.Video, only: [build_url: 1]
      iex> build_url(%{youtube_id: "dQw4w9WgXcQ"})
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  """
  def build_url(%{youtube_id: id}) when not is_nil(id),
    do: "https://www.youtube.com/watch?v=#{id}"

  def build_url(%{facebook_id: id}) when not is_nil(id),
    do: "https://www.facebook.com/video.php?v=#{id}"

  # Add a special case for building test URLs
  if Application.get_env(:db, :env) == :test do
    def build_url(%{youtube_id: id, facebook_id: fb_id}),
      do: "__TEST__/#{id || fb_id}"
  end

  @doc """
  Returns overview image url for the given video
  """
  def image_url(_video = %__MODULE__{thumbnail: url}) when not is_nil(url) do
    url
  end

  def image_url(_video = %__MODULE__{youtube_id: id}) when not is_nil(id) do
    youtube_thumbnail(id)
  end

  def image_url(_video) do
    # Facebook doesn't make it easy to fetch the thumbnail, so we use the default YouTube's one
    "https://img.youtube.com/vi/default/mqdefault.jpg"
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :title, :language])
    |> validate_required([:url, :title])
    |> parse_video_url()
    |> validate_length(:title, min: 5, max: 120)
    |> unique_constraint(:videos_youtube_id_index)
    |> unique_constraint(:videos_facebook_id_index)
    # Change locales like "en-US" to "en"
    |> update_change(:language, &hd(String.split(&1, "-")))
  end

  @doc """
  Generate hash ID for video

  ## Examples

      iex> DB.Schema.Video.changeset_generate_hash_id(%DB.Schema.Video{id: 42, hash_id: nil})
      #Ecto.Changeset<action: nil, changes: %{hash_id: \"4VyJ\"}, errors: [], data: #DB.Schema.Video<>, valid?: true>
  """
  def changeset_generate_hash_id(video = %{id: id}) do
    change(video, hash_id: VideoHashId.encode(id))
  end

  @doc """
  Builds a changeset that allows shifting statements for all providers

  ## Examples

      iex> DB.Schema.Video.changeset_shift_offsets(%DB.Schema.Video{}, %{youtube_offset: 42})
      #Ecto.Changeset<action: nil, changes: %{youtube_offset: 42}, errors: [], data: #DB.Schema.Video<>, valid?: true>
  """
  def changeset_shift_offsets(struct, params \\ %{}) do
    cast(struct, params, [:youtube_offset])
  end

  @doc """
  Given a changeset, fill the `{provider}_id` fields or add an error if URL is not valid.
  """
  def parse_video_url(changeset = %Ecto.Changeset{}) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{url: url}} ->
        case parse_url(url) do
          {:youtube, id} ->
            changeset
            |> put_change(:youtube_id, id)
            |> put_change(:thumbnail, youtube_thumbnail(id))

          {:facebook, id} ->
            put_change(changeset, :facebook_id, id)

          _ ->
            add_error(changeset, :url, "invalid_url")
        end

      _ ->
        changeset
    end
  end

  @doc """
  Parse an URL.
  Given a binary, return {provider, id} or nil if invalid.

  ## Examples

      iex> import DB.Schema.Video, only: [parse_url: 1]
      iex> parse_url ""
      nil
      iex> parse_url "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
      {:youtube, "dQw4w9WgXcQ"}
      iex> parse_url "https://www.youtube.com/watch?v="
      nil
      iex> parse_url "https://www.facebook.com/brutofficiel/videos/une-carte-mondiale-du-qi-/628554354575815/"
      {:facebook, "628554354575815"}
  """
  def parse_url(url) when is_binary(url) do
    Enum.find_value(@providers_regexs, fn {provider, regex} ->
      case Regex.named_captures(regex, url) do
        %{"id" => id, "id2" => id2, "id3" => id3, "id4" => id4} ->
          {provider,
           Enum.find([id, id2, id3, id4], fn id_to_test ->
             not is_nil(id_to_test) and String.length(id_to_test) > 0
           end)}

        %{"id" => id} ->
          {provider, id}

        nil ->
          nil
      end
    end)
  end

  defp youtube_thumbnail(id) do
    "https://img.youtube.com/vi/#{id}/mqdefault.jpg"
  end

  defp filter_with(query, filters) do
    Enum.reduce(filters, query, fn
      {:language, "unknown"}, query ->
        from(v in query, where: is_nil(v.language))

      {:language, language}, query ->
        from(v in query, where: v.language == ^language)

      {:speaker_id, id}, query ->
        from(v in query, join: s in assoc(v, :speakers), where: s.id == ^id)

      {:speaker_slug, slug}, query ->
        from(v in query, join: s in assoc(v, :speakers), where: s.slug == ^slug)

      {:min_id, id}, query ->
        from(v in query, where: v.id > ^id)

      {:is_partner, is_partner}, query ->
        from(v in query, where: v.is_partner == ^is_partner)
    end)
  end
end
