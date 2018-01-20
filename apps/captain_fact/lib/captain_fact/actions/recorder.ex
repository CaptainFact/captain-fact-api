defmodule CaptainFact.Actions.Recorder do
  import Ecto.Query, warn: false
  import CaptainFact.Actions.UserAction, only: [type: 1, entity: 1]

  alias Ecto.Multi
  alias DB.Repo
  alias CaptainFact.Actions.UserAction
  alias CaptainFact.Accounts.User


  @doc"""
  Record an action for user. User can be a %User{} struct or a user_id integer
  Return {:ok, action} on success or {:error, action_changeset} on failure
  """
  def record(user, action_type, entity, params \\ %{}) do
    Repo.insert(build_action_changeset(user, action_type, entity, params))
  end

  @doc"""
  A helper to make the transition from deprecated VideoDebateAction smoother
  """
  def record(changeset = %Ecto.Changeset{data: %UserAction{}}) do
    Repo.insert(changeset)
  end

  @doc"""
  Record an action for user. User can be a %User{} struct or a user_id integer
  Return action
  """
  def record!(user, action_type, entity, params \\ %{}) do
    Repo.insert!(build_action_changeset(user, action_type, entity, params))
  end

  @doc"""
  ⚠️ Admin-only function. Record action as done by the system or an admin
  """
  def admin_record!(action_type, entity, params \\ %{}) do
    params = Map.merge(params, %{type: type(action_type), entity: entity(entity)})
    Repo.insert!(UserAction.admin_changeset(%UserAction{}, params))
  end

  @doc"""
  ⚠️ Admin-only function. Record multiples actions as done by the system or an admin as a single query.
  This is useful to log actions on multiple users at the same time
  """
  def admin_record_all!(action_type, entity, actions_params) do
    datetime = Ecto.DateTime.utc
    Repo.insert_all(UserAction, Enum.map(actions_params, fn params ->
      Map.merge params, %{user_id: nil, type: type(action_type), entity: entity(entity), inserted_at: datetime}
    end))
  end

  @doc"""
  Same as record/4 but act on an Ecto.Multi object. Action is recorded under `:action_record` key
  """
  def multi_record(multi, user, action_type, entity, params \\ %{}) do
    Multi.insert(multi, :action_record, build_action_changeset(user, action_type, entity, params))
  end

  @doc"""
  Count all actions with `action_type` type for this entity
  max_age: max action oldness (in seconds)
  """
  def count_wildcard(user, action_type, max_age \\ -1) do
    UserAction
    |> where([a], a.user_id == ^user_id(user))
    |> where([a], a.type == ^UserAction.type(action_type))
    |> age_filter(max_age)
    |> Repo.aggregate(:count, :id)
  end

  @doc"""
  Count all actions with `action_type` type and matching `entity` for this entity
  max_age: max action oldness (in seconds)
  """
  def count(user, action_type, entity, max_age \\ -1) do
    UserAction
    |> where([a], a.user_id == ^user_id(user))
    |> where([a], a.type == ^UserAction.type(action_type))
    |> where([a], a.entity == ^UserAction.entity(entity))
    |> age_filter(max_age)
    |> Repo.aggregate(:count, :id)
  end

  # ---- Private methods ----

  defp build_action_changeset(user, action_type, entity, params) do
    action = Ecto.build_assoc(user(user), :actions)
    params = Map.merge(params, %{type: type(action_type), entity: entity(entity)})
    UserAction.changeset(action, params)
  end

  defp age_filter(query, -1), do: query
  defp age_filter(query, age),
    do: where(query, [a], a.inserted_at >= ^NaiveDateTime.add(NaiveDateTime.utc_now, -age))

  # Utils
  defp user(user = %User{}), do: user
  defp user(id) when is_integer(id), do: %User{id: id}

  defp user_id(%{id: id}), do: id
  defp user_id(id) when is_integer(id), do: id
end