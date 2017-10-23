defmodule CaptainFactWeb.Router do
  use CaptainFactWeb, :router

  # ---- Pipelines ----

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  # ---- Routes ----

  scope "/", CaptainFactWeb do
    pipe_through [:api]

    # Public endpoints
    get "/", ApiInfoController, :get
    get "/videos", VideoController, :index
    get "/videos/:video_id/statements", StatementController, :get
    post "/search/video", VideoController, :search
    post  "/videos", VideoController, :get_or_create

    # Authenticathed endpoints
    scope "/" do
      pipe_through [:api_auth]

      # Authentication
      scope "/auth" do
        get    "/", AuthController, :me
        delete "/", AuthController, :delete
        post   "/:provider/callback", AuthController, :callback

        scope "/reset_password" do
          post "/request", AuthController, :reset_password_request
          get  "/verify/:token", AuthController, :reset_password_verify
          post "/confirm", AuthController, :reset_password_confirm
        end

        post   "/request_invitation", AuthController, :request_invitation
      end

      # Users
      scope "/users" do
        post   "/", UserController, :create
        delete "/me", UserController, :delete
        put    "/me", UserController, :update
        get    "/me/available_flags", UserController, :available_flags
        put    "/me/confirm_email/:token", UserController, :confirm_email
        get    "/me", UserController, :show_me
        get    "/:username", UserController, :show
      end
    end
  end

  # Dev only : mailer. We can use Mix.env here cause file is interpreted at compile time
  if Mix.env == :dev do
    pipeline :browser do
      plug :accepts, ["html"]
    end

    scope "/jouge42/mail" do
      pipe_through [:browser]
      forward "/sent_emails", Bamboo.SentEmailViewerPlug
    end
  end
end
