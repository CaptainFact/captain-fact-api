defmodule CaptainFactGraphqlWeb.Router do
  use CaptainFactGraphqlWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :api

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: CaptainFactGraphql.Schema,
      context: %{pubsub: CaptainFactGraphql.Endpoint}

    forward "/", Absinthe.Plug,
      schema: CaptainFactGraphql.Schema,
      analyze_complexity: true,
      max_complexity: 280 # (5 joins = 250) + 30 fields
  end
end
