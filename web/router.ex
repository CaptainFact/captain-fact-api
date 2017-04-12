defmodule CaptainFact.Router do
  use CaptainFact.Web, :router
  use ExAdmin.Router

  # ---- Pipelines ----

  # Browser (backadmin)

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end

  pipeline :browser_auth do
    plug Guardian.Plug.EnsureAuthenticated
    plug CaptainFact.Plugs.SuperAdmin
  end

  # API

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  # ---- Routes ----

  scope "/admin", CaptainFact do
    pipe_through :browser
    get "/login", UserController, :admin_login
  end

  scope "/admin", ExAdmin do
    pipe_through [:browser, :browser_auth]
    admin_routes()
  end

  scope "/api", CaptainFact do
    pipe_through [:api, :api_auth]

    scope "/auth" do
      get "/me", AuthController, :me
      get "/:provider", AuthController, :request
      post "/:identity/callback", AuthController, :callback
      delete "/signout", AuthController, :delete
    end

    post "/users", UserController, :create
    put "/users/:user_id", UserController, :update
    get "/users/:username", UserController, :show
    get "/users/:user_id/videos", VideoController, :index

    resources "/videos", VideoController, only: [:index, :create, :update, :delete]

    get "/search/users/:query_string", UserController, :search
    get "/utils/external_video_title/:video_uri", VideoController, :youtube_title
  end

end
