defmodule CF.Graphql.Schema.Types do
  use Absinthe.Schema.Notation

  import_types(CF.Graphql.Schema.Types.{
    AppInfo,
    Comment,
    Notification,
    Paginated,
    Source,
    Speaker,
    Statement,
    Statistics,
    Subscription,
    UserAction,
    User,
    Video
  })
end
