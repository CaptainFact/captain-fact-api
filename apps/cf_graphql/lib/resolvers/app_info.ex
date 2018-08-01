defmodule CF.GraphQL.Resolvers.AppInfo do
  def info(_, _args, _info) do
    {:ok,
     %{
       status: "✔",
       version: CF.GraphQL.Application.version(),
       db_version: DB.Application.version()
     }}
  end
end
