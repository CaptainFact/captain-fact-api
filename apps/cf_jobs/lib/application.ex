defmodule CF.Jobs.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Wait 10s before starting to give some time for the migrations to run
    :timer.sleep(1000)

    env = Application.get_env(:cf, :env)

    # Define workers and child supervisors to be supervised
    children = [
      # Jobs
      worker(CF.Jobs.Reputation, []),
      worker(CF.Jobs.Flags, []),
      worker(CF.Jobs.Moderation, []),
      worker(CF.Jobs.CreateNotifications, []),
      worker(CF.Jobs.DownloadCaptions, [])
    ]

    # Do not start scheduler in tests
    children =
      if env == :test or Application.get_env(:cf, :disable_scheduler),
        do: children,
        else: children ++ [worker(CF.Jobs.Scheduler, [])]

    opts = [strategy: :one_for_one, name: CF.Jobs.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Get app's version from `mix.exs`
  """
  def version() do
    case :application.get_key(:cf, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end
end
