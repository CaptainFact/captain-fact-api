defmodule CF.Graphql.Schema.InputObjects do
  use Absinthe.Schema.Notation

  import_types(CF.Graphql.Schema.InputObjects.{
    VideoFilter,
    StatementFilter
  })
end
