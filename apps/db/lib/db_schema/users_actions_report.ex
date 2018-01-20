defmodule DB.Schema.UsersActionsReport do
  use Ecto.Schema
  import Ecto.Changeset
  alias DB.Schema.UsersActionsReport


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

  def analyser_id(:reputation), do: 1
  def analyser_id(:flags), do: 2
  def analyser_id(:achievements), do: 3
  def analyser_id(:votes), do: 4

  def status(:pending), do: 1
  def status(:running), do: 2
  def status(:success), do: 3
  def status(:failed), do: 4
end
