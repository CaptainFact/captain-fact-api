defmodule Opengraph.Application do
  use Application

  alias Opengraph.Router

  def start(_, _) do
    Router.start_link()
  end
end
