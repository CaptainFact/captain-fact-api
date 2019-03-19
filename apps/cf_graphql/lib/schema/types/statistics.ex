defmodule CF.Graphql.Schema.Types.Statistics do
  @moduledoc """
  Various application statistics, like the number of users, the number of
  comments...
  """

  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo
  alias CF.Graphql.Resolvers

  @desc "Statistics about the platform community"
  object :statistics do
    @desc "All totals"
    field(:totals, :statistic_totals, do: resolve(&Resolvers.Statistics.all_totals/3))
    @desc "List the 20 best users"
    field(:leaderboard, list_of(:user), do: resolve(&Resolvers.Statistics.leaderboard/2))
  end

  @desc "Counts for all public CF tables"
  object :statistic_totals do
    field(:users, non_null(:integer))
    field(:comments, non_null(:integer))
    field(:statements, non_null(:integer))
    field(:sources, non_null(:integer))
  end
end
