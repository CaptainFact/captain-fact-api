defmodule CaptainFact.Actions.UsersActionsReport do
  use Ecto.Schema
  import Ecto.Changeset
  alias CaptainFact.Actions.{UsersActionsReport, Analysers}


  schema "users_actions_reports" do
    field :analyser_id, :integer
    field :last_action_id, :integer
    field :status, :integer

    # Various stats
    field :nb_actions, :integer
    field :nb_entries_updated, :integer
    field :run_duration, :integer

    timestamps()
  end

  @required [:analyser_id, :status, :last_action_id, :nb_actions]

  @doc false
  def changeset(%UsersActionsReport{} = users_actions_report, attrs) do
    users_actions_report
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def analyser_id(Analysers.Reputation), do: 1
  def analyser_id(Analysers.Flags), do: 2
  def analyser_id(Analysers.AchievementUnlocker), do: 2

  def status(:pending), do: 1
  def status(:running), do: 2
  def status(:success), do: 3
  def status(:failed), do: 4
end
