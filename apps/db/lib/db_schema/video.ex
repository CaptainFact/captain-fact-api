defmodule DB.Schema.Video do
  @moduledoc"""
  Ecto schema for `videos` table.
  """

  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias DB.Schema.{Speaker, Statement, VideoSpeaker}

  schema "videos" do
    field :title, :string
    field :url, :string, virtual: true
    field :provider, :string, null: false
    field :provider_id, :string, null: false
    field :language, :string, null: true
    field :unlisted, :boolean, null: false
    field :is_partner, :boolean, null: false

    many_to_many :speakers, Speaker, join_through: VideoSpeaker, on_delete: :delete_all
    has_many :statements, Statement, on_delete: :delete_all

    timestamps()
  end

  # Define valid providers

  @providers_regexs %{
    # Map a provider name to its regex, using named_captures to get the id --------------------↘️
    "youtube" => ~r/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)(?<id>[^"&?\/ ]{11})/i
  }

  # Allow for URLs like `https://anything.com/__TEST__/ID` in tests
  if Application.get_env(:db, :env) == :test do
    @providers_regexs Map.put(@providers_regexs, "__TEST__", ~r/__TEST__\/(?<id>[^"&?\/ ]+)/)
  end

  # Define queries

  @doc"""
  Select all videos not unlisted and order them by id.

  ## Params

    * query: an Ecto query
    * filters: a list of tuples like {filter_name, value}.
      Valid filters:
        - language: `unknwown` or locale (`fr`, `en`...)
        - speaker_id: speaker's integer ID
        - speaker_slug: speaker's slug
        - min_id: select all videos with id above given integer
  """
  def query_list(query, filters \\ []) do
    query
    |> where([v], v.unlisted == false)
    |> order_by([v], desc: v.id)
    |> filter_with(filters)
  end

  @doc"""
  Preload speakers for given video query
  """
  def with_speakers(query) do
    from v in query, preload: [:speakers]
  end

  @doc"""
  Preload statements for given video query
  """
  def with_statements(query) do
    from v in query, preload: [:statements]
  end

  # Utils

  @doc"""
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

  @doc"""
  Build an URL for given video.

  ## Examples

      iex> import DB.Schema.Video, only: [build_url: 1]
      iex> build_url(%{provider: "youtube", provider_id: "dQw4w9WgXcQ"})
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  """
  def build_url(%{provider: "youtube", provider_id: id}),
    do: "https://www.youtube.com/watch?v=#{id}"

  # Add a special case for building test URLs
  if Application.get_env(:db, :env) == :test do
    def build_url(%{provider: "__TEST__", provider_id: id}),
      do: "__TEST__/#{id}"
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :title, :language])
    |> validate_required([:url, :title])
    |> parse_url()
    |> validate_required([:provider, :provider_id])
    |> validate_length(:title, min: 5, max: 120)
    |> unique_constraint(:videos_provider_provider_id_index)
    |> update_change(:language, &(hd(String.split(&1, "-")))) # Change "en-US" to "en"
  end

  @doc"""
  Parse an URL.
  If given a changeset, fill the `provider` and `provider_id` fields or add
  an error if URL is not valid.
  If given a binary, return {provider, id} or nil if invalid.

  ## Examples

      iex> import DB.Schema.Video, only: [parse_url: 1]
      iex> parse_url ""
      nil
      iex> parse_url "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
      {"youtube", "dQw4w9WgXcQ"}
      iex> parse_url "https://www.youtube.com/watch?v="
      nil
  """
  def parse_url(changeset = %Ecto.Changeset{}) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{url: url}} ->
        case parse_url(url) do
          {provider, id} ->
            changeset
            |> put_change(:provider, provider)
            |> put_change(:provider_id, id)
          _ ->
            add_error(changeset, :url, "invalid_url")
        end
      _ ->
        changeset
    end
  end

  def parse_url(url) when is_binary(url) do
    Enum.find_value(@providers_regexs, fn {provider, regex} ->
      case Regex.named_captures(regex, url) do
        %{"id" => id} ->
          {provider, id}
        nil ->
          nil
      end
    end)
  end

  defp filter_with(query, filters) do
    Enum.reduce(filters, query, fn
      {:language, "unknown"}, query ->
        from v in query, where: is_nil(v.language)
      {:language, language}, query ->
        from v in query, where: v.language == ^language
      {:speaker_id, id}, query ->
        from v in query, join: s in assoc(v, :speakers), where: s.id == ^id
      {:speaker_slug, slug}, query ->
        from v in query, join: s in assoc(v, :speakers), where: s.slug == ^slug
      {:min_id, id}, query ->
        from v in query, where: v.id > ^id
      {:is_partner, is_partner}, query ->
        from v in query, where: v.is_partner == ^is_partner
    end)
  end
end
