defmodule CF.AtomFeed.Router do
  use Plug.Router
  require Logger

  plug(Plug.Head)
  plug(:match)
  plug(:dispatch)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_opts \\ []) do
    config = Application.get_env(:cf_atom_feed, CF.AtomFeed.Router)
    Logger.info("Running CF.AtomFeed.Router with cowboy on port #{config[:cowboy][:port]}")
    Plug.Cowboy.http(CF.AtomFeed.Router, [], config[:cowboy])
  end

  get "/" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, """
      {
        "app": "CF.AtomFeed",
        "status": "✔",
        "version": "#{CF.AtomFeed.Application.version()}",
        "db_version": "#{DB.Application.version()}"
      }
    """)
  end

  @feed_content_type "application/atom+xml"

  defp render_feed(conn, feed_content) do
    conn
    |> put_resp_content_type(@feed_content_type)
    |> send_resp(200, feed_content)
  end

  get "/comments" do
    render_feed(conn, CF.AtomFeed.Comments.feed_all())
  end

  get "/statements" do
    render_feed(conn, CF.AtomFeed.Statements.feed_all())
  end

  get "/videos" do
    render_feed(conn, CF.AtomFeed.Videos.feed_all())
  end

  get "/flags" do
    render_feed(conn, CF.AtomFeed.Flags.feed_all())
  end
end
