defmodule CF.Opengraph.Application do
  use Application

  alias CF.Opengraph.Router

  def start(_, _) do
    children = [
      %{
        id: CF.Opengraph.Router,
        start: {Router, :start_link, []}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
