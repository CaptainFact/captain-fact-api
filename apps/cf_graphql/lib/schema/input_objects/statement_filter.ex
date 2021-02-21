defmodule CF.Graphql.Schema.InputObjects.StatementFilter do
  @moduledoc """
  Represent the possible filters to apply to statement.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo

  @desc "Props to filter statements on"
  input_object :statement_filter do
    field(:commented, :boolean)
  end
end
