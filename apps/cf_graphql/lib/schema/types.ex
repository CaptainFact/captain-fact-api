defmodule CF.GraphQL.Schema.Types do
  use Absinthe.Schema.Notation

  import_types(CF.GraphQL.Schema.Types.{
    AppInfo,
    Comment,
    Paginated,
    Source,
    Speaker,
    Statement,
    Statistics,
    UserAction,
    User,
    Video
  })
end
