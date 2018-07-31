defmodule CaptainFactJobs.Job do
  @moduledoc """
  Behaviour for CaptainFact jobs.
  """

  alias DB.Schema.UsersActionsReport

  @default_timeout 60_000 # 1 minute

  def __using__(opts) do
    alias DB.Schema.UserAction

    # Variables
    name = __MODULE__
    integer_id = UsersActionsReport.analyser_id(Keyword.get(opts, :id))
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    raw_watched_actions = Keyword.get(opts, :watched_actions, [])

    # Ensure required params are provided
    if Enum.empty?(raw_watched_actions),
      do: raise("watched_actions must be provided for job #{name}")

    # Prepare
    watched_actions = Enum.map(raw_watched_actions, &(UserAction.type(&1)))

    # Actual implementation
    quote do
      use GenServer
      import Ecto.Query

      def start_link() do
        GenServer.start_link(unquote(name), :ok, name: unquote(name))
      end

      def init(args) do
        {:ok, args}
      end

      def update() do
        GenServer.call(unquote(name), :update, unquote(timeout))
      end

      # def handle_call(:update, _, _) do
      #   last_action_id = ReportManager.get_last_action_id(@analyser_id)
      #   unless last_action_id == -1 do
      #     UserAction
      #     |> where([a], a.id > ^last_action_id)
      #     |> where([a], a.type in ^@watched_actions)
      #     |> Repo.all(log: false)
      #     |> start_analysis()
      #   end
      #   {:reply, :ok , :ok}
      # end
    end
  end
end