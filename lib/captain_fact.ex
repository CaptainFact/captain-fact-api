defmodule CaptainFact do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    CaptainFact.Weave.configure()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(CaptainFact.Repo, []),
      # Start the endpoint when the application starts
      supervisor(CaptainFactWeb.Endpoint, []),
      # Other custom workers
      supervisor(CaptainFact.Sources.Fetcher, []),
      worker(CaptainFact.Accounts.ReputationUpdater, []),
      worker(CaptainFact.Actions.FlagsAnalyser, []),
      worker(CaptainFact.Comments.VoteDebouncer, []),
      worker(CaptainFact.VideoHashId, []),
      worker(CaptainFact.Accounts.UsernameGenerator, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CaptainFact.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
