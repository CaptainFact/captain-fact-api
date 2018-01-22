defmodule CaptainFactGraphql.Resolvers.AppInfo do
  def info(_, _args, _info) do
    {:ok, %{
      status: "✔",
      version: CaptainFactGraphql.Application.version(),
      db_version: DB.Application.version()
    }}
  end
end