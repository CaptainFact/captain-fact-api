defmodule CF.Graphql.Resolvers.AppInfo do
  # Mix is not available at runtime in OTP releases; bake env at compile time.
  @mix_env Mix.env()

  def info(_, _args, _info) do
    {:ok,
     %{
       app: "CF.Graphql",
       status: "✔",
       version: CF.Graphql.Application.version(),
       db_version: DB.Application.version(),
       env: Application.get_env(:cf, :deploy_env),
       host: Application.get_env(:cf, :host),
       mix_env: @mix_env
     }}
  end
end
