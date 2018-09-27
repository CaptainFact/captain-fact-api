defmodule CF.GraphQL.Schema.Types.Video do
  @moduledoc """
  Representation of a `DB.Schema.Video` for Absinthe
  """

  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo
  import CF.Graphql.Schema.Utils
  alias CF.GraphQL.Resolvers

  import_types(CF.GraphQL.Schema.Types.{Paginated, Statement, Speaker})

  @desc "Identifies a video. Only Youtube is supported at the moment"
  object :video do
    @desc "Unique identifier as an integer"
    field(:id, non_null(:id))
    @desc "Unique identifier as a hash (min length: 4) - used in URL"
    field(:hash_id, non_null(:string))
    @desc "Video title as extracted from provider"
    field(:title, non_null(:string))
    @desc "Video URL"
    field(:url, non_null(:string), do: resolve(&Resolvers.Videos.url/3))
    @desc "Video provider (youtube, vimeo...etc)"
    field(:provider, non_null(:string))
    @desc "Unique ID used to identify video with provider"
    field(:provider_id, non_null(:string))
    @desc "Language of the video represented as a two letters locale"
    field(:language, :string)
    @desc "List all non-removed speakers for this video"
    field :speakers, list_of(:speaker) do
      resolve(assoc(:speakers))
      complexity(join_complexity())
    end

    @desc "List all non-removed statements for this video"
    field :statements, list_of(:statement) do
      resolve(&Resolvers.Videos.statements/3)
      complexity(join_complexity())
    end
  end

  @desc "A list a paginated videos"
  object :paginated_videos do
    import_fields(:paginated)
    field(:entries, list_of(:video))
  end
end
