defmodule CF.Graphql.Schema.Types.Statement do
  @moduledoc """
  Representation of a `DB.Schema.Statement` for Absinthe
  """

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import CF.Graphql.Schema.Utils

  @desc "A transcript or a description of the picture"
  object :statement do
    field(:id, non_null(:id))
    @desc "Speaker's transcript or image description"
    field(:text, non_null(:string))
    @desc "Statement timecode, in seconds"
    field(:time, non_null(:integer))
    @desc "Whether the statement is in draft mode"
    field(:is_draft, non_null(:boolean))

    @desc "Statement's speaker. Null if statement describes picture"
    field :speaker, :speaker do
      resolve(dataloader(DB.Repo))
      complexity(join_complexity())
    end

    @desc "List of users comments and facts for this statement"
    field :comments, list_of(:comment) do
      resolve(dataloader(DB.Repo))
      complexity(join_complexity())
    end

    @desc "The video associated with this statement"
    field :video, :video do
      resolve(dataloader(DB.Repo))
      complexity(join_complexity())
    end
  end

  @desc "A list a paginated statements"
  object :paginated_statements do
    import_fields(:paginated)
    field(:entries, list_of(:statement))
  end
end
