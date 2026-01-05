defmodule CF.Graphql.Schema.Types.Flag do
  @moduledoc """
  Representation of a `DB.Schema.Flag` for Absinthe
  """

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import CF.Graphql.Schema.Utils

  @desc "A flag on an action"
  object :flag do
    @desc "User who created the flag"
    field :source_user, :user do
      resolve(dataloader(DB.Repo))
      complexity(join_complexity())
    end

    @desc "Reason for the flag"
    field(:reason, :flag_reason)
  end
end
