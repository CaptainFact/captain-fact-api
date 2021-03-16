defmodule CF.Graphql.Resolvers.Statements do
  @moduledoc """
  Resolver for `DB.Schema.Statement`
  """

  alias Kaur.Result

  import Ecto.Query
  import Absinthe.Resolution.Helpers, only: [batch: 3]

  alias DB.Repo
  alias DB.Schema.Statement

  # Queries

  def paginated_list(_root, args = %{offset: offset, limit: limit}, _info) do
    Statement
    |> Statement.query_list(Map.get(args, :filters, []))
    |> Repo.paginate(page: offset, page_size: limit)
    |> Result.ok()
  end
end
