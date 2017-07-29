defmodule CaptainFact.Flagger do

  require Logger
  import Ecto.Query

  alias CaptainFact.Accounts.{UserPermissions, ReputationUpdater}
  alias CaptainFact.{Repo, VideoHashId}
  alias CaptainFactWeb.{Flag, Comment, Statement, Endpoint}

  @comments_nb_flags_to_ban 3

  @doc """
  Record a new flag on `comment` requested by given user `user_id`
  """
  def flag!(comment = %Comment{}, reason, source_user_id, async \\ true) do
    UserPermissions.lock!(source_user_id, :flag_comment, fn user ->
      Ecto.build_assoc(user, :flags_posted)
      |> Flag.changeset_comment(comment, %{reason: reason})
      |> Repo.insert!()
    end)
    if async,
      do: Task.start_link(fn -> check_comment_flags(comment) end),
      else: check_comment_flags(comment)
  end

  def comments_nb_flags_to_ban(), do: @comments_nb_flags_to_ban

  # TODO revert_ban

  def get_nb_flags(%Comment{id: comment_id}) do
    Flag
    |> where([f], f.type == ^Flag.comment_type)
    |> where([f], f.entity_id == ^comment_id)
    |> Repo.aggregate(:count, :id)
  end

  defp check_comment_flags(comment = %Comment{id: comment_id}) do
    if get_nb_flags(comment) < @comments_nb_flags_to_ban do
      ReputationUpdater.register_action_without_source(comment.user_id, :comment_flagged, false)
    else
      # Careful : update_all doesn't update `updated_at` field
      {nb_updated, [comment]} = Repo.update_all((
          from c in Comment,
          where: c.id == ^comment_id,
          where: c.is_banned == false
        ), [set: [is_banned: true]], returning: true
      )
      if nb_updated == 1 do
        Logger.debug("Comment #{comment_id} banned")
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
        # Update reputation synchronously
        ReputationUpdater.register_action_without_source(comment.user_id, :comment_banned, false)
      end
    end
  end
end