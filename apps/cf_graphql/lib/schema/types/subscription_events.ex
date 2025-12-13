defmodule CF.Graphql.Schema.Types.SubscriptionEvents do
  @moduledoc """
  GraphQL event payloads for subscription responses.
  """

  use Absinthe.Schema.Notation

  @desc "Reference to a removed speaker"
  object :speaker_removed do
    field(:id, non_null(:id))
  end

  @desc "Reference to a removed statement"
  object :statement_removed do
    field(:id, non_null(:id))
  end

  @desc "Reference to a removed comment"
  object :comment_removed do
    field(:id, non_null(:id))
    field(:statement_id, :id)
    field(:reply_to_id, :id)
  end

  @desc "Reference to a flagged comment"
  object :comment_flagged do
    field(:id, non_null(:id))
  end

  @desc "Reference to a comment involved in a score update"
  object :comment_reference do
    field(:id, non_null(:id))
    field(:statement_id, :id)
    field(:reply_to_id, :id)
  end

  @desc "A score diff published after a vote"
  object :comment_score_diff do
    field(:comment, non_null(:comment_reference))
    field(:diff, non_null(:integer))
  end
end
