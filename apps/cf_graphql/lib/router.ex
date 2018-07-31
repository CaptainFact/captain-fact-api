defmodule CF.GraphQLWeb.Router do
  use CF.GraphQLWeb, :router

  @graphiql_route "/graphiql"

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug BasicAuth, use_config: {:cf_graphql, :basic_auth}
  end

  scope "/" do
    pipe_through :api

    scope @graphiql_route do
      if Mix.env == :prod, do: pipe_through :authenticated

      forward "/", Absinthe.Plug.GraphiQL,
        schema: CF.GraphQL.Schema,
        analyze_complexity: true,
        max_complexity: 320, # (6 joins = 300) + 20 fields
        context: %{pubsub: CF.GraphQLWeb.Endpoint}
    end

    forward "/", Absinthe.Plug,
      schema: CF.GraphQL.Schema,
      analyze_complexity: true,
      max_complexity: 320 # (6 joins = 300) + 20 fields
  end
end
