defmodule CF.Graphql.Schema.Types.Speaker do
  @moduledoc """
  Representation of a `DB.Schema.Speaker` for Absinthe
  """

  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo
  import CF.Graphql.Schema.Utils
  alias CF.Graphql.Resolvers

  @desc "A speaker appearing in one or more videos"
  object :speaker do
    field(:id, non_null(:id))
    @desc "A unique slug to identify the speaker"
    field(:slug, :string)
    @desc "Full name"
    field(:full_name, non_null(:string))

    @desc "Official title (can have multiple separated by a comma). Ex: Politician, activist, writer"
    field(:title, :string)
    @desc "Country code of the speaker's origin (from wikidata)"
    field(:country, :string)
    @desc "Wikidata unique identifier, without the 'Q' prefix"
    field(:wikidata_item_id, :string)
    @desc "Speaker's picture URL. Format is 50x50"
    field(:picture, :string, do: resolve(&Resolvers.Speakers.picture/3))
    @desc "List of speaker's videos"
    field :videos, list_of(:video) do
      resolve(assoc(:videos))
      complexity(join_complexity())
    end
  end
end
