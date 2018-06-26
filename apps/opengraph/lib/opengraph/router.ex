defmodule Opengraph.Router do
  use Plug.Router
  alias Kaur.Result
  alias Opengraph.Generator
  require Logger

  plug Plug.Logger, log: :debug
  plug :match
  plug :dispatch

  def start_link do
    port = 4005 # TODO load config
    success_logging =
      fn _ ->
        Logger.info("Running Opengraph.Router with cowboy on port #{port}")
      end

    failure_logging =
      fn error ->
        Logger.error("Unable to start Opengraph router : #{error}")
      end

    Plug.Adapters.Cowboy.http(__MODULE__, [], [port: port])
    |> Result.tap(success_logging)
    |> Result.tap_error(failure_logging)
  end

  get "/u/:username" do
    username = conn.params["username"]
    user =
      DB.Schema.User
      |> DB.Repo.get_by(username: username)

    if is_nil(user) do
      send_resp(conn, 404, "not_found")
    else
      user
      |> Generator.user_tags
      |> Result.map(&Generator.generate_html/1)
      |> Result.either(
        fn _error ->
          conn
          |> send_resp(500, "there has been an unexpected error")
        end,
        fn body ->
          send_resp(conn, 200, body)
        end
      )
    end
  end

  # get "/videos" do
  #   opengraphs = """
  #   <html>
  #     <head>
  #       <meta property="og:title" content="Discover crowd fact checked videos on Captain Fact">
  #       <meta property="og:type" content=
  #     </head>
  #   </html>
  #   """
  # end

  # get "/videos/:video_id" do
  #   VideoController.get(conn)
  # end

  # get "/videos/:video_id/history" do
  #   VideoController.get_history(conn)
  # end

  # get "/s/:slug_or_id" do
  #   SpeakerController.get(conn)
  # end

  match _ do
    conn
    |> send_resp(404, "NOT FOUND")
  end

end
