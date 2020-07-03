defmodule CF.GraphQLWeb.Router do
  use CF.GraphQLWeb, :router

  @graphiql_route "/graphiql"

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :api_auth do
    plug(:accepts, ["json"])
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
        max_complexity: 400
      )
    end

    forward(
      "/",
      Absinthe.Plug,
      schema: CF.Graphql.Schema,
      analyze_complexity: true,
      max_complexity: 400
    )
  end
end
