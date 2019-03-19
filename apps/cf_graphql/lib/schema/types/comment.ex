defmodule CF.Graphql.Schema.Types.Comment do
  @moduledoc """
  Representation of a `DB.Schema.Comment` for Absinthe
  """

  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo
  import CF.Graphql.Schema.Utils
  alias CF.Graphql.Resolvers

  @desc "A user's comment. A comment will be considered being a fact if it has a source"
  object :comment do
    field(:id, non_null(:id))
    @desc "User who made the comment"
    field :user, :user do
      resolve(assoc(:user))
      complexity(join_complexity())
    end

    @desc "Text of the comment. Can be null if the comment has a source"
    field(:text, :string)
    @desc "Can be true / false (facts) or null (comment)"
    field(:approve, :boolean)
    @desc "Datetime at which the comment has been added"
    field(:inserted_at, :string)
    @desc "Score of the comment / fact, based on users votes"
    field :score, non_null(:integer) do
      resolve(&Resolvers.Comments.score/3)
      complexity(join_complexity())
    end

    @desc "Source of the scomment. If null, a text must be set"
    field :source, :source do
      resolve(assoc(:source))
      complexity(join_complexity())
    end

    @desc "If this comment is a reply, this will point toward the comment being replied to"
    field(:reply_to_id, :id)
  end
end
