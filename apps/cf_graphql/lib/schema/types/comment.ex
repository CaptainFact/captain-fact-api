defmodule CF.Graphql.Schema.Types.Comment do
  @moduledoc """
  Representation of a `DB.Schema.Comment` for Absinthe
  """

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import CF.Graphql.Schema.Utils
  alias CF.Graphql.Resolvers

  @desc "Reason for flagging a comment"
  enum :flag_reason do
    value(:bad_language, description: "Personal attack or inappropriate language", as: 1)
    value(:spam, description: "Unwanted commercial content or spam", as: 2)
    value(:irrelevant, description: "Irrelevant", as: 3)
    value(:not_constructive, description: "Not constructive", as: 4)
  end

  @desc "A user's comment. A comment will be considered being a fact if it has a source"
  object :comment do
    field(:id, non_null(:id))
    @desc "User who made the comment"
    field :user, :user do
      resolve(dataloader(DB.Repo))
      complexity(join_complexity())
    end

    @desc "Text of the comment. Can be null if the comment has a source"
    field(:text, :string)
    @desc "Can be true / false (facts) or null (comment)"
    field(:approve, :boolean)
    @desc "Datetime at which the comment has been added"
    field(:inserted_at, non_null(:naive_datetime))
    @desc "Score of the comment / fact, based on users votes"
    field :score, non_null(:integer) do
      resolve(&Resolvers.Comments.score/3)
      complexity(join_complexity())
    end

    @desc "Source of the scomment. If null, a text must be set"
    field :source, :source do
      resolve(dataloader(DB.Repo))
      complexity(join_complexity())
    end

    @desc "If this comment is a reply, this will point toward the comment being replied to"
    field(:reply_to_id, :id)
    @desc "ID of the statement this comment belongs to"
    field(:statement_id, :id)
  end
end
