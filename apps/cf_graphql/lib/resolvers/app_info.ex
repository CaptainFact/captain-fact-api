defmodule CF.Graphql.Resolvers.AppInfo do
  def info(_, _args, _info) do
    {:ok,
     %{
       app: "CF.Graphql",
       status: "✔",
       version: CF.Graphql.Application.version(),
       db_version: DB.Application.version()
     }}
  end
end
