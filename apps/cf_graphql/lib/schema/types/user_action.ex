defmodule CF.Graphql.Schema.Types.UserAction do
  @moduledoc """
  Representation of a `DB.Schema.UserAction` for Absinthe
  """

  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo
  import CF.Graphql.Schema.Utils
  alias DB.Type.VideoHashId

  @desc "Describe a user action"
  object :user_action do
    @desc "Unique action ID"
    field(:id, non_null(:id))
    @desc "User who made the action"
    field :user, :user do
      resolve(assoc(:user))
      complexity(join_complexity())
    end

    @desc "User targeted by the action"
    field :target_user, :user do
      resolve(assoc(:target_user))
      complexity(join_complexity())
    end

    @desc "Action type"
    field(:type, non_null(:string))
    @desc "Entity type"
    field(:entity, non_null(:string))
    @desc "Datetime at which the action has been done"
    field(:time, :string, do: resolve(fn a, _, _ -> {:ok, a.inserted_at} end))
    @desc "Video ID where the action took place"
    field(:video_id, :integer)
    @desc "Video hash ID where the action took place"
    field(
      :video_hash_id,
      :string,
      do:
        resolve(fn a, _, _ ->
          {:ok, a.video_id && VideoHashId.encode(a.video_id)}
        end)
    )

    @desc "Speaker impacted by this action"
    field(:speaker_id, :integer)
    @desc "Statement impacted by this action"
    field(:statement_id, :integer)
    @desc "Comment impacted by this action"
    field(:comment_id, :integer)

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

    @desc "A map with all the changes made by this action"
    field(
      :changes,
      :string,
      do:
        resolve(fn a, _, _ ->
          {:ok, Poison.encode!(a.changes)}
        end)
    )
  end
end
