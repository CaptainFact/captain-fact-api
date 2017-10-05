defmodule CaptainFact.Actions.Recorder do
  import Ecto.Query, warn: false
  import CaptainFact.Actions.UserAction, only: [type: 1, entity: 1]

  alias CaptainFact.Repo
  alias CaptainFact.Actions.UserAction
  alias CaptainFact.Accounts.User


  def record!(user, action_type, entity, params \\ %{}) do
    Ecto.build_assoc(user(user), :actions)
    |> UserAction.changeset(Map.merge(params, %{type: type(action_type), entity: entity(entity)}))
    |> Repo.insert!()
  end

  def count(user, action_type) do
    UserAction
    |> where([a], a.user_id == ^user_id(user))
    |> where([a], a.type == ^UserAction.type(action_type))
    |> Repo.aggregate(:count, :id)
  end

  def count(user, action_type, entity) do
    UserAction
    |> where([a], a.user_id == ^user_id(user))
    |> where([a], a.type == ^UserAction.type(action_type))
    |> where([a], a.entity == ^UserAction.entity(entity))
    |> Repo.aggregate(:count, :id)
  end

  # Utils
  defp user(user = %User{}), do: user
  defp user(id) when is_integer(id), do: %User{id: id}

  defp user_id(%{id: id}), do: id
  defp user_id(id) when is_integer(id), do: id
end