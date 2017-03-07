defmodule CaptainFact.PageController do
  use CaptainFact.Web, :controller

  #TODO: Remove

  def index(conn, _params) do
    render conn, "index.html"
  end
end
