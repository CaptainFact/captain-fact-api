defmodule CaptainFactAtomFeed.Router do
  use Plug.Router
  require Logger

  plug :match
  plug :dispatch

  def start_link do
    config = Application.get_env(:captain_fact_atom_feed, CaptainFactAtomFeed.Router)
    Logger.info("Running CaptainFactAtomFeed.Router with cowboy on port #{config[:cowboy][:port]}")
    Plug.Adapters.Cowboy.http(CaptainFactAtomFeed.Router, [], config[:cowboy])
  end

  get "/" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, """
      {
        "status": "✔",
        "version": "#{CaptainFactAtomFeed.Application.version()}",
        "db_version": "#{DB.Application.version()}"
      }
    """)
  end

  @feed_content_type "application/atom+xml"

  get "/comments" do
    conn
    |> put_resp_content_type(@feed_content_type)
    |> send_resp(200, CaptainFactAtomFeed.Comments.feed_all())
  end
end
