defmodule CaptainFact do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    CaptainFact.Weave.configure()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(CaptainFactWeb.Endpoint, []),
      # Other custom supervisors
      supervisor(CaptainFact.Sources.Fetcher, []),
      # Scheduler for all CRON jobs (like action analyzers below)
      worker(CaptainFact.Scheduler, []),
      # Actions analyzers
      worker(CaptainFact.Actions.Analyzers.Reputation, []),
      worker(CaptainFact.Actions.Analyzers.Flags, []),
      worker(CaptainFact.Actions.Analyzers.Achievements, []),
      worker(CaptainFact.Actions.Analyzers.Votes, []),
      # Other CRON tasks
      worker(CaptainFact.Moderation.Updater, []),
      # Misc workers
      worker(CaptainFact.Videos.VideoHashId, []), # TODO [DbRefactor] Move
      worker(CaptainFact.Accounts.UsernameGenerator, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CaptainFact.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def version() do
    case :application.get_key(:captain_fact, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end

  @doc """
  If Mix is available, returns Mix.env(). If not available (in releases) return :prod
  """
  def env() do
    (Kernel.function_exported?(Mix, :env, 0) && Mix.env) || :prod
  end
end
