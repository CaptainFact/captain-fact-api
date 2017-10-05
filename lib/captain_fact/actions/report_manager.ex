defmodule CaptainFact.Actions.ReportManager do
  import Ecto.Query
  alias CaptainFact.Repo
  alias CaptainFact.Actions.UsersActionsReport

  def get_last_report(analyser_id) do
    UsersActionsReport
    |> where([r], r.analyser_id == ^analyser_id)
    |> order_by([r], desc: r.id)
    |> limit(1)
    |> Repo.one()
  end

  def create_report!(analyser_id, status, actions, params \\ %{}) do
    Repo.insert! UsersActionsReport.changeset(%UsersActionsReport{}, Map.merge(%{
      analyser_id: analyser_id,
      last_action_id: Enum.max(actions, &(&1.id)).id,
      status: UsersActionsReport.status(status),
      nb_actions: Enum.count(actions)
    }, params))
  end

  def update_report!(report, params \\ %{}) do
    Repo.update!(UsersActionsReport.changeset(report, params))
  end
end