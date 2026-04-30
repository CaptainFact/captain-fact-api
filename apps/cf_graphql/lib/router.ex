defmodule CF.GraphQLWeb.Router do
  use CF.GraphQLWeb, :router

  @graphiql_route "/graphiql"

  pipeline :api do
    # html + json so browser traffic to /graphiql, favicon, etc. does not hit
    # plug :accepts only ["json"] → Phoenix.NotAcceptableError and huge error logs.
    plug(:accepts, ["html", "json"])
  end

  pipeline :api_auth do
    plug(:accepts, ["html", "json"])
    plug(CF.Graphql.AuthPipeline)
  end

  scope "/" do
    pipe_through(:api_auth)

    scope @graphiql_route do
      forward(
        "/",
        Absinthe.Plug.GraphiQL,
        schema: CF.Graphql.Schema,
        analyze_complexity: true,
        max_complexity: 500
      )
    end

    forward(
      "/",
      CF.Graphql.CustomAbsinthePlug,
      schema: CF.Graphql.Schema,
      analyze_complexity: true,
      max_complexity: 500
    )
  end
end
