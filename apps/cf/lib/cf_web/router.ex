defmodule CF.Web.Router do
  use CF.Web, :router

  alias CF.Authenticator.GuardianImpl

  # ---- Pipelines ----

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :api_auth do
    plug(GuardianImpl.Pipeline)
    plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
    plug(Guardian.Plug.LoadResource, allow_blank: true)
  end

  # -------- Routes --------

  scope "/", CF.Web do
    pipe_through([:api])

    # ---- Public endpoints ----
    get("/", ApiInfoController, :get)
    get("/videos", VideoController, :index)
    get("/videos/index", VideoController, :index_ids)
    get("/speakers/:slug_or_id", SpeakerController, :show)
    post("/search/video", VideoController, :search)
    get("/videos/:video_id/statements", StatementController, :get)
    get("/newsletter/unsubscribe/:token", UserController, :newsletter_unsubscribe)

    # ---- Authenticathed endpoints ----
    scope "/" do
      pipe_through([:api_auth])

      # Authentication
      scope "/auth" do
        delete("/", AuthController, :logout)
        delete("/:provider/link", AuthController, :unlink_provider)
        post("/:provider/callback", AuthController, :callback)
      end

      # Users
      scope "/users" do
        post("/", UserController, :create)
        post("/request_invitation", UserController, :request_invitation)
        get("/username/:username", UserController, :show)

        scope "/reset_password" do
          post("/request", UserController, :reset_password_request)
          get("/verify/:token", UserController, :reset_password_verify)
          post("/confirm", UserController, :reset_password_confirm)
        end

        scope "/me" do
          get("/", UserController, :show_me)
          put("/", UserController, :update)
          delete("/", UserController, :delete)
          get("/available_flags", UserController, :available_flags)
          put("/confirm_email/:token", UserController, :confirm_email)
          put("/achievements/:achievement", UserController, :unlock_achievement)
          post("/onboarding/complete_step", UserController, :complete_onboarding_step)
          post("/onboarding/complete_steps", UserController, :complete_onboarding_steps)
          delete("/onboarding", UserController, :delete_onboarding)
        end
      end

      # Videos
      post("/videos", VideoController, :get_or_create)

      # Moderation
      get("/moderation/random", ModerationController, :random)
      post("/moderation/feedback", ModerationController, :post_feedback)
    end
  end

  # ---- Dev only: mailer. We can use Mix.env here cause file is interpreted at compile time ----
  if Mix.env() == :dev do
    pipeline :browser do
      plug(:accepts, ["html"])
    end

    scope "/jouge42" do
      pipe_through([:browser])
      forward("/mail", Bamboo.SentEmailViewerPlug)
    end
  end
end
