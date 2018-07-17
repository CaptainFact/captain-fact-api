defmodule CaptainFact.Actions.Recorder do
  import Ecto.Query, warn: false
  import DB.Schema.UserAction, only: [type: 1, entity: 1]

  alias Ecto.Multi
  alias DB.Repo
  alias DB.Schema.UserAction
  alias DB.Schema.User

  @doc """
  Record an action for user. User can be a %User{} struct or a user_id integer
  Return {:ok, action} on success or {:error, action_changeset} on failure
  """
  def record(user, action_type, entity, params \\ %{}) do
    Repo.insert(build_action_changeset(user, action_type, entity, params))
  end

  @doc """
  A helper to make the transition from deprecated VideoDebateAction smoother
  """
  def record(changeset = %Ecto.Changeset{data: %UserAction{}}) do
    Repo.insert(changeset)
  end

  @doc """
  Record an action for user. User can be a %User{} struct or a user_id integer
  Return action
  """
  def record!(user, action_type, entity, params \\ %{}) do
    Repo.insert!(build_action_changeset(user, action_type, entity, params))
  end

  @doc """
  ⚠️ Admin-only function. Record action as done by the system or an admin
  """
  def admin_record!(action_type, entity, params \\ %{}) do
    params = Map.merge(params, %{type: type(action_type), entity: entity(entity)})
    Repo.insert!(UserAction.changeset_admin(%UserAction{}, params))
  end

  @doc """
  ⚠️ Admin-only function. Record multiples actions as done by the system or an admin as a single query.
  This is useful to log actions on multiple users at the same time
  """
  def admin_record_all!(action_type, entity, actions_params) do
    Repo.insert_all(
      UserAction,
      Enum.map(actions_params, fn params ->
        Map.merge(params, %{
          user_id: nil,
          type: type(action_type),
          entity: entity(entity),
          inserted_at: Ecto.DateTime.utc()
        })
      end)
    )
  end

  @doc """
  Same as record/4 but act on an Ecto.Multi object. Action is recorded under `:action_record` key
  """
  def multi_record(multi, user, action_type, entity, params \\ %{}) do
    Multi.insert(multi, :action_record, build_action_changeset(user, action_type, entity, params))
  end

  # ---- Private methods ----

  defp build_action_changeset(user, action_type, entity, params) do
    action = Ecto.build_assoc(user(user), :actions)
    params = Map.merge(params, %{type: type(action_type), entity: entity(entity)})
    UserAction.changeset(action, params)
  end

  # Utils

  defp user(user = %User{}), do: user
  defp user(id) when is_integer(id), do: %User{id: id}
end
