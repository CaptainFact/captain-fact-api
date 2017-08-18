defmodule CaptainFactWeb.Router do
  use CaptainFactWeb, :router
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
    plug CaptainFactWeb.Plugs.SuperAdmin
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

  # APIs

  scope "/api", CaptainFactWeb do
    pipe_through [:api, :api_auth]

    # Authentication
    scope "/auth" do
      get    "/", AuthController, :me
      delete "/", AuthController, :delete
      get    "/:provider/callback", AuthController, :callback
      post   "/:provider/callback", AuthController, :callback

      scope "/reset_password" do
        post "/request", AuthController, :reset_password_request
        get  "/verify/:token", AuthController, :reset_password_verify
        post "/confirm", AuthController, :reset_password_confirm
      end

      post   "/request_invitation", AuthController, :request_invitation
    end

    # Users
    post   "/users", UserController, :create
    delete "/users/me", UserController, :delete
    put    "/users/me", UserController, :update
    get    "/users/me/available_flags", UserController, :available_flags
    put    "/users/me/confirm_email/:token", UserController, :confirm_email
    get    "/users/me", UserController, :show_me
    get    "/users/:username", UserController, :show
    get    "/users/:user_id/videos", VideoController, :index

    # Videos
    get   "/videos", VideoController, :index
    post  "/videos", VideoController, :get_or_create
  end

  scope "/extension_api", CaptainFactWeb do
    pipe_through [:api, :api_auth]

    # Statements
    get   "/videos/:video_id/statements", StatementController, :get
    post  "/search/video", VideoController, :search
  end

  # Browser (backadmin)

  scope "/jouge42", CaptainFactWeb do
    pipe_through :browser
    get    "/login", UserController, :admin_login
    delete "/logout", UserController, :admin_logout
  end

  scope "/jouge42/admin", ExAdmin do
    pipe_through [:browser, :browser_auth]
    admin_routes()
  end

  # Dev only : mailer. We can use Mix.env here cause file is interpreted at compile time
  if Mix.env == :dev do
    scope "/jouge42/mail" do
      pipe_through [:browser, :browser_auth]
      forward "/sent_emails", Bamboo.SentEmailViewerPlug
    end
  end
end
