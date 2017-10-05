defmodule CaptainFact.Flagger do

  require Logger
  import Ecto.Query

  alias CaptainFact.Accounts.{UserPermissions, User}
  alias CaptainFact.{Repo, VideoHashId}
  alias CaptainFact.Actions.Recorder
  alias CaptainFact.Comments.Comment
  alias CaptainFactWeb.{Flag, Statement, Endpoint}


  @comments_nb_flags_to_ban 3

  @doc """
  Record a new flag on `comment` requested by given user `user_id`
  """
  def flag!(comment = %Comment{}, reason, source_user_id, async \\ true) do
    user = Repo.get!(User, source_user_id)
    UserPermissions.check!(user, :flag, :comment)
    Ecto.build_assoc(user, :flags_posted)
    |> Flag.changeset_comment(comment, %{reason: reason})
    |> Repo.insert!()
    Recorder.record!(user, :flag, :comment, %{target_user_id: comment.user_id})

    if async,
      do: Task.start(fn -> check_comment_flags(comment, get_nb_flags(comment)) end),
      else: check_comment_flags(comment, get_nb_flags(comment))
  end

  def comments_nb_flags_to_ban(), do: @comments_nb_flags_to_ban

  # TODO revert_ban

  def get_nb_flags(%Comment{id: comment_id}) do
    Flag
    |> where([f], f.type == ^Flag.comment_type)
    |> where([f], f.entity_id == ^comment_id)
    |> Repo.aggregate(:count, :id)
  end

  # TODO This should append in a GenServer call
  defp check_comment_flags(_comment, nb_flags) when nb_flags != @comments_nb_flags_to_ban,
    do: nil # Ignore additional flags
  defp check_comment_flags(%Comment{id: comment_id}, @comments_nb_flags_to_ban) do
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
    end
  end
end