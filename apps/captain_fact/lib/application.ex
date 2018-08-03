defmodule CaptainFact.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Load runtime configuration
    CaptainFact.RuntimeConfiguration.setup()
    CaptainFact.RuntimeConfiguration.configure()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(CaptainFactWeb.Endpoint, []),
      # Other custom supervisors
      supervisor(CaptainFact.Sources.Fetcher, []),
      # Presence to track number of connected users to a channel
      supervisor(CaptainFactWeb.Presence, []),
      # Scheduler for all CRON jobs
      worker(CaptainFact.Scheduler, []),
      # Jobs
      worker(CaptainFactJobs.Reputation, []),
      worker(CaptainFactJobs.Flags, []),
      worker(CaptainFactJobs.Achievements, []),
      worker(CaptainFactJobs.Votes, []),
      worker(CaptainFactJobs.Moderation, []),
      # Misc workers
      worker(CaptainFact.Accounts.UsernameGenerator, []),
      # Sweep tokens from db
      worker(Guardian.DB.Token.SweeperServer, [])
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
  deprecated, use Application.get_env(:captain_fact, :env)
  """
  def env() do
    (Kernel.function_exported?(Mix, :env, 0) && Mix.env()) || :prod
  end
end
