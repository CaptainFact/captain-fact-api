defmodule CaptainFact.Actions.Flagger do
  require Logger
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.User
  alias DB.Schema.Comment
  alias DB.Schema.UserAction
  alias DB.Schema.Flag

  alias CaptainFact.Accounts.UserPermissions
  alias CaptainFact.Actions.Recorder

  @doc """
  Record a new flag on `comment` requested by given user `user_id`
  """
  @action_create UserAction.type(:create)
  @entity_comment UserAction.entity(:comment)
  def flag!(source_user_id, %Comment{id: comment_id}, reason),
    do: flag!(source_user_id, comment_id, reason)

  def flag!(source_user_id, comment_id, reason) do
    user = Repo.get!(User, source_user_id)
    UserPermissions.check!(user, :flag, :comment)
    action_id = get_action_id!(@action_create, @entity_comment, comment_id)

    try do
      user
      |> Ecto.build_assoc(:flags_posted)
      |> Flag.changeset(%{reason: reason, action_id: action_id})
      |> Repo.insert!()
    rescue
      # Ignore if flag already exist
      Ecto.ConstraintError ->
        :ok
    else
      _ -> Recorder.record!(user, :flag, :comment, %{entity_id: comment_id})
    end
  end

  @doc """
  Get the total number of flags for given entity.
  `entity` can be passed as an integer or an atom (converted with UserAction.entity)
  """
  def get_nb_flags(%Comment{id: id}),
    do: get_nb_flags(:create, :comment, id)

  def get_nb_flags(action_type, entity, id) when is_atom(action_type),
    do: get_nb_flags(UserAction.type(action_type), entity, id)

  def get_nb_flags(action_type, entity, id) when is_atom(entity),
    do: get_nb_flags(action_type, UserAction.entity(entity), id)

  def get_nb_flags(action_type, entity, id) when is_integer(entity) do
    Flag
    |> join(:inner, [f], a in assoc(f, :action))
    |> where([_, a], a.type == ^action_type)
    |> where([_, a], a.entity == ^entity)
    |> where([_, a], a.entity_id == ^id)
    |> Repo.aggregate(:count, :id)
  end

  defp get_action_id!(action_type, entity, id) do
    UserAction
    |> where([a], a.type == ^action_type)
    |> where([a], a.entity == ^entity)
    |> where([a], a.entity_id == ^id)
    |> select([a], a.id)
    |> Repo.one!()
  end
end
