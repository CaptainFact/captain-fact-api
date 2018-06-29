defmodule Opengraph.Router do
  use Plug.Router
  alias Kaur.Result
  alias Opengraph.Generator
  require Logger

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  def start_link do
    # TODO load config
    port = 4005

    success_logging = fn _ ->
      Logger.info("Running Opengraph.Router with cowboy on port #{port}")
    end

    failure_logging = fn error ->
      Logger.error("Unable to start Opengraph router : #{error}")
    end

    Plug.Adapters.Cowboy.http(__MODULE__, [], port: port)
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
      |> Generator.user_tags()
      |> Result.map(&Generator.generate_html/1)
      |> Result.either(
        fn _error ->
          conn
          |> send_resp(500, "there has been an unexpected error")
        end,
        fn body ->
          conn
          |> put_resp_content_type("text/html")
          |> send_resp(200, body)
        end
      )
    end
  end

  get "/videos" do
    Generator.videos_list_tags()
    |> Result.map(&Generator.generate_html/1)
    |> Result.either(
      fn _error ->
        conn
        |> send_resp(500, "there has been an unexpected error")
      end,
      fn body ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, body)
      end
    )
  end

  get "/videos/:video_id/*_" do
    conn.params["video_id"]
    |> DB.Type.VideoHashId.decode
    |> Result.map(&CaptainFact.Videos.get_video_by_id/1)
    |> Result.and_then(&Result.from_value/1)
    |> Result.and_then(&Generator.video_tags/1)
    |> Result.map(&Generator.generate_html/1)
    |> Result.either(
      fn error ->
        case error do
          :no_value -> send_resp(conn, 404, "content not found")
          _ -> conn
            |> send_resp(500, "there has been an unexpected error")
        end
      end,
      fn body ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, body)
      end
    )
  end

  # get "/s/:slug_or_id" do

  # end

  match _ do
    conn
    |> send_resp(404, "NOT FOUND")
  end
end
