defmodule CaptainFactGraphqlWeb.Router do
  use CaptainFactGraphql, :router

  @graphiql_route "/graphiql"

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug BasicAuth, use_config: {:captain_fact_graphql, :basic_auth}
  end

  scope "/" do
    pipe_through :api

    scope @graphiql_route do
      if Mix.env == :prod, do: pipe_through :authenticated

      forward "/", Absinthe.Plug.GraphiQL,
        schema: CaptainFactGraphql.Schema,
        analyze_complexity: true,
        max_complexity: 320, # (6 joins = 300) + 20 fields
        context: %{pubsub: CaptainFactGraphqlWeb.Endpoint}
    end

    forward "/", Absinthe.Plug,
      schema: CaptainFactGraphql.Schema,
      analyze_complexity: true,
      max_complexity: 320 # (6 joins = 300) + 20 fields
  end
end
