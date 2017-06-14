defmodule CaptainFact.Flagger do

  require Logger
  import Ecto.Query
  alias CaptainFact.{Flag, Comment, UserPermissions, Repo}

  @comments_nb_flags_to_ban 3

  @doc """
  Record a new flag on `comment` requested by given user `user_id`
  """
  def flag!(comment = %Comment{}, reason, source_user_id) do
    UserPermissions.lock!(source_user_id, :flag_comment, fn user ->
      Ecto.build_assoc(user, :flags_posted)
      |> Flag.changeset_comment(comment, %{reason: reason})
      |> Repo.insert!()
    end)
    Task.start(fn -> check_comment_flags(comment) end)
  end

  # TODO revert_flag

  defp check_comment_flags(%Comment{id: comment_id}) do
    nb_flags = Repo.one(
      from f in Flag,
      select: count(f.id),
      where: f.type == ^Flag.comment_type,
      where: f.entity_id == ^comment_id
    )

    if nb_flags >= @comments_nb_flags_to_ban do
      {nb_updated, _comments} = Repo.update_all(
        (
          from c in Comment,
          where: c.id == ^comment_id,
          where: c.is_banned == false
        ),
        set: [is_banned: true]
      )

      if nb_updated == 1 do
        Logger.info("Comment #{comment_id} banned")
        # TODO Update user reputation
        # TODO Inform channel (delete comments[0])
      end
    end
  end
end