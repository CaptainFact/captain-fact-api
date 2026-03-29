defmodule CF.Graphql.Schema.Types.ModerationEntry do
  @moduledoc """
  Representation of a `CF.Moderation.ModerationEntry` for Absinthe
  """

  use Absinthe.Schema.Notation

  @desc "A moderation entry containing an action and its flags"
  object :moderation_entry do
    @desc "The action that needs moderation"
    field(:action, non_null(:user_action))

    @desc "Flags associated with this action"
    field(:flags, non_null(list_of(:flag)))
  end
end
