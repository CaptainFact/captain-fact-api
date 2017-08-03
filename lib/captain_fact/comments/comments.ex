defmodule CaptainFact.Comments do
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.Comments.{Comment, Vote}
  alias CaptainFact.Accounts.{UserPermissions, ReputationUpdater}
  alias CaptainFact.Sources.{Fetcher, Source}

  # ---- Add comment ----

  def add_comment(user, params, source_url, source_fetch_callback \\ nil) do
    # TODO [Security] What if reply_to_id refer to a comment that is on a different statement ?
    source = source_url && (Repo.get_by(Source, url: source_url) || %{url: source_url})
    comment = UserPermissions.lock!(user, :add_comment, fn user ->
      user
      |> Ecto.build_assoc(:comments)
      |> Ecto.Changeset.change(%{})
      |> Ecto.Changeset.put_assoc(:source, source)
      |> Comment.changeset(params)
      |> Repo.insert!()
    end)
    full_comment = comment |> Map.put(:user, user) |> Repo.preload(:source) |> Map.put(:score, 1)
    Task.start(fn() -> vote(user, full_comment.id, 1) end) # Self vote
    unless is_nil(source) || Map.get(source, :id, false), # If new source
      do: fetch_source_metadata_and_update_comment(comment, source_fetch_callback)
    full_comment
  end

  # Metadata fetching

  defp fetch_source_metadata_and_update_comment(%Comment{source: nil}, _), do: nil
  defp fetch_source_metadata_and_update_comment(comment = %Comment{source: source}, callback) do
    Fetcher.fetch_source_metadata(source.url, fn
      {:error, _} -> nil
      {:ok, source_params} when source_params == %{} -> nil
      {:ok, source_params} ->
        # TODO Check if this url already exists. If it does, merge it and remove this source
        updated_source = Repo.update!(Source.changeset(source, source_params))
        # TODO Comment may have been edited. Reload from DB
        if callback, do: callback.(Map.put(comment, :source, updated_source))
    end)
  end

  # ---- Vote ----

  def vote(user, comment_id, value) do
    # Find initial comment
    comment =
      Comment.with_source(Comment, false)
      |> select([:user_id])
      |> Repo.get(comment_id)

    # Define vote type (self, up, down)
    action = cond do
      user.id == comment.user_id -> :self_vote
      value >= 0 -> :vote_up
      true -> :vote_down
    end

    {base_vote, new_vote} = UserPermissions.lock!(user, action, fn user ->
      base_vote =
        Repo.get_by(Vote, user_id: user.id, comment_id: comment_id) ||
        %Vote{user_id: user.id, comment_id: comment_id}
      new_vote = Repo.insert_or_update!(Vote.changeset(base_vote, %{value: value}))
      {base_vote, new_vote}
    end)
    with true <- action != :self_vote,
         vote_type when not is_nil(vote_type) <- Vote.get_vote_type(comment, base_vote.value, new_vote.value) do
      ReputationUpdater.register_action(user.id, comment.user_id, vote_type)
    end
    new_vote
  end
end