defmodule CF.Graphql.Schema.Types.Paginated do
  @moduledoc """
  A generic pagination object
  """

  use Absinthe.Schema.Notation

  object :paginated do
    field(:page_number, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:total_entries, :integer)
  end
end
