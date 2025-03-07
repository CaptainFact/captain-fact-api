defmodule CF.Graphql.Schema.InputObjects.StatementFilter do
  @moduledoc """
  Represent the possible filters to apply to statement.
  """

  use Absinthe.Schema.Notation

  @desc "Props to filter statements on"
  input_object :statement_filter do
    field(:commented, :boolean)
    field(:is_draft, :boolean)
    field(:speaker_id, :id)
  end
end
