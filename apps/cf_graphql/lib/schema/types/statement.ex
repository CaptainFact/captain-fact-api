defmodule CF.Graphql.Schema.Types.Statement do
  @moduledoc """
  Representation of a `DB.Schema.Statement` for Absinthe
  """

  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo
  import CF.Graphql.Schema.Utils

  import_types(CF.Graphql.Schema.Types.{Speaker, Comment})

  @desc "A transcript or a description of the picture"
  object :statement do
    field(:id, non_null(:id))
    @desc "Speaker's transcript or image description"
    field(:text, non_null(:string))
    @desc "Statement timecode, in seconds"
    field(:time, non_null(:integer))
    @desc "Statement's speaker. Null if statement describes picture"
    field :speaker, :speaker do
      resolve(assoc(:speaker))
      complexity(join_complexity())
    end

    @desc "List of users comments and facts for this statement"
    field :comments, list_of(:comment) do
      resolve(assoc(:comments))
      complexity(join_complexity())
    end
  end
end
