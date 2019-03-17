defmodule CF.Graphql.Schema.Types.Subscription do
  @moduledoc """
  User subscriptions to entities changes, used by notifications generator.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo

  import CF.Graphql.Schema.Utils
  alias DB.Type.VideoHashId

  @desc "A user subscription to entities changes, used by notifications generator"
  object :notifications_subscription do
    @desc "Unique user ID"
    field(:id, non_null(:id))

    @desc "The scope of the subscription"
    field(:scope, non_null(:string))

    @desc "The reason why user has subscribed"
    field(:reason, :string)

    @desc "Is the subscription active?"
    field(:is_subscribed, non_null(:boolean))

    # Associations IDs

    @desc "Associated video ID"
    field(:video_id, :integer)

    @desc "Associated video hash ID"
    field(
      :video_hash_id,
      :string,
      do:
        resolve(fn a, _, _ ->
          {:ok, a.video_id && VideoHashId.encode(a.video_id)}
        end)
    )

    @desc "Associated statement ID"
    field(:statement_id, :integer)

    @desc "Associated comment ID"
    field(:comment_id, :integer)

    # Associations

    @desc "Associated video"
    field :video, :video do
      complexity(join_complexity())
      resolve(assoc(:video))
    end

    @desc "Associated statement"
    field :statement, :statement do
      complexity(join_complexity())
      resolve(assoc(:statement))
    end

    @desc "Associated comment"
    field :comment, :comment do
      complexity(join_complexity())
      resolve(assoc(:comment))
    end
  end
end
