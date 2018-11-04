defmodule CF.Actions.Flagger do
  require Logger
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.User
  alias DB.Schema.Comment
  alias DB.Schema.UserAction
  alias DB.Schema.Flag

  alias CF.Accounts.UserPermissions
  alias CF.Actions.ActionCreator

  @doc """
  Record a new flag on `comment` requested by given user `user_id`
  """
  def flag!(source_user_id, video_id, comment_id, reason) when is_integer(comment_id),
    do: flag!(source_user_id, video_id, Repo.get!(Comment, comment_id), reason)

  def flag!(source_user_id, video_id, comment = %Comment{}, reason) do
    user = Repo.get!(User, source_user_id)
    UserPermissions.check!(user, :flag, :comment)
    action_id = get_action_id!(:create, :comment, comment.id)

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
      _ ->
        Repo.insert!(ActionCreator.action_flag(source_user_id, video_id, comment))
    end
  end

  @doc """
  Get the total number of flags for given entity.
  `entity` can be passed as an integer or an atom (converted with UserAction.entity)
  """
  def get_nb_flags(%Comment{id: id}),
    do: get_nb_flags(:create, :comment, id)

  @spec get_nb_flags(DB.Type.UserActionType.t(), atom(), integer()) :: integer()
  def get_nb_flags(action_type, entity, id) do
    Flag
    |> join(:inner, [f], a in assoc(f, :action))
    |> where([_, a], a.type == ^action_type)
    |> where([_, a], a.entity == ^entity)
    |> where([_, a], a.comment_id == ^id)
    |> Repo.aggregate(:count, :id)
  end

  defp get_action_id!(action_type, entity, id) do
    UserAction
    |> where([a], a.type == ^action_type)
    |> where([a], a.entity == ^entity)
    |> where([a], a.comment_id == ^id)
    |> select([a], a.id)
    |> Repo.one!()
  end
end
