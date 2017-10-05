defmodule CaptainFact.Actions.Flagger do

  require Logger
  import Ecto.Query

  alias CaptainFact.Accounts.{UserPermissions, User}
  alias CaptainFact.Repo
  alias CaptainFact.Actions.{Recorder, UserAction}
  alias CaptainFact.Comments.Comment
  alias CaptainFactWeb.Flag


  @doc"""
  Record a new flag on `comment` requested by given user `user_id`
  """
  def flag!(comment = %Comment{}, reason, source_user_id) do
    user = Repo.get!(User, source_user_id)
    UserPermissions.check!(user, :flag, :comment)
    Ecto.build_assoc(user, :flags_posted)
    |> Flag.changeset_comment(comment, %{reason: reason})
    |> Repo.insert!()
    Recorder.record!(user, :flag, :comment, %{target_user_id: comment.user_id, entity_id: comment.id})
  end

  def get_nb_flags(%Comment{id: id}), do: get_nb_flags(:comment, id)

  @doc"""
  Get the total number of flags for given entity.
  `entity` can be passed as an integer or an atom (converted with UserAction.entity)
  """
  def get_nb_flags(entity, id) when is_atom(entity), do: get_nb_flags(UserAction.entity(entity), id)
  def get_nb_flags(entity, id) when is_integer(entity) do
    Flag
    |> where([f], f.entity == ^entity)
    |> where([f], f.entity_id == ^id)
    |> Repo.aggregate(:count, :id)
  end
end