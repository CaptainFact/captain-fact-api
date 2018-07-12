defmodule CF.Opengraph.Application do
  use Application

  alias CF.Opengraph.Router

  def start(_, _) do
    port = Application.get_env(:cf_opengraph, :port)

    children = [
      %{
        id: CF.Opengraph.Router,
        start: {Router, :start_link, [port]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
