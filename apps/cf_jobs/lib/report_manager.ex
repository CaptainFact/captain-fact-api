defmodule CF.Jobs.ReportManager do
  import Ecto.Query
  # TODO Implement this as a behaviour

  alias DB.Repo
  alias DB.Schema.UsersActionsReport

  def get_last_report(analyser_id) do
    UsersActionsReport
    |> where([r], r.analyser_id == ^analyser_id)
    |> order_by([r], desc: r.id)
    |> limit(1)
    # Don't log queries as report queries happen very often
    |> Repo.one(log: false)
  end

  @doc """
  Return last treated action id. If an analyser is already `:running` for this `analyser_id`, return value will be -1.
  If not report exists, returns 0
  """
  def get_last_action_id(analyser_id) do
    case get_last_report(analyser_id) do
      nil -> 0
      %{status: :running} -> -1
      report -> report.last_action_id
    end
  end

  def create_report!(analyser_id, status, actions, params \\ %{}) do
    Repo.insert!(
      UsersActionsReport.changeset(
        %UsersActionsReport{},
        Map.merge(
          %{
            analyser_id: analyser_id,
            last_action_id: Enum.max_by(actions, & &1.id).id,
            status: UsersActionsReport.status(status),
            nb_actions: Enum.count(actions)
          },
          params
        )
      )
    )
  end

  def update_report!(report, params \\ %{}) do
    Repo.update!(UsersActionsReport.changeset(report, params))
  end

  def set_success!(report, nb_entries_updated \\ 0) do
    update_report!(report, %{
      nb_entries_updated: nb_entries_updated,
      run_duration: NaiveDateTime.diff(NaiveDateTime.utc_now(), report.inserted_at),
      status: UsersActionsReport.status(:success)
    })
  end

  def show_running() do
    UsersActionsReport
    |> where([r], r.status == ^UsersActionsReport.status(:running))
    |> DB.Repo.all()
  end

  def show_pending() do
    UsersActionsReport
    |> where([r], r.status == ^UsersActionsReport.status(:pending))
    |> DB.Repo.all()
  end

  def show_failed() do
    UsersActionsReport
    |> where([r], r.status == ^UsersActionsReport.status(:pending))
    |> DB.Repo.all()
  end
end
