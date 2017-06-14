defmodule CaptainFact.Flagger do

  require Logger
  import Ecto.Query

  alias CaptainFact.{
    Flag, Comment, Statement, UserPermissions, Repo, Endpoint, VideoHashId, ReputationUpdater
  }

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

  # TODO revert_ban

  defp check_comment_flags(comment = %Comment{id: comment_id}) do
    nb_flags = Repo.one(
      from f in Flag,
      select: count(f.id),
      where: f.type == ^Flag.comment_type,
      where: f.entity_id == ^comment_id
    )

    if nb_flags >= @comments_nb_flags_to_ban do
      # Careful : update_all doesn't update `updated_at` field
      {nb_updated, [comment]} = Repo.update_all(
        (
          from c in Comment,
          where: c.id == ^comment_id,
          where: c.is_banned == false
        ),
        [set: [is_banned: true]],
        returning: true
      )
      if nb_updated > 0 do
        Logger.info("Comment #{comment_id} banned")
        # TODO Update user reputation
        comment_context = Repo.one!(
          from c in Comment,
            join: s in Statement, on: c.statement_id == s.id,
            where: c.id == ^comment.id,
            select: %{video_id: s.video_id, statement_id: s.id}
        )
        Endpoint.broadcast(
          "comments:video:#{VideoHashId.encode(comment_context.video_id)}",
          "comment_removed",
          %{id: comment_id, statement_id: comment_context.statement_id}
        )
        ReputationUpdater.register_action_without_source(comment.user_id, :comment_banned)
      end
    end
  end
end