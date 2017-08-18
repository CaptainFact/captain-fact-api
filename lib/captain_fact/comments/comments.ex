defmodule CaptainFact.Comments do
  import Ecto.{Query}
  require Logger

  alias CaptainFact.Repo
  alias CaptainFact.Comments.{Comment, Vote}
  alias CaptainFact.Accounts.{UserPermissions, ReputationUpdater}
  alias CaptainFact.Sources.{Fetcher, Source}


  # ---- Public API ----

  def add_comment(user, params, source_url, source_fetch_callback \\ nil) do
    # TODO [Security] What if reply_to_id refer to a comment that is on a different statement ?
    source = source_url && (Repo.get_by(Source, url: source_url) || %{url: source_url})
    comment_changeset =
      user
      |> Ecto.build_assoc(:comments)
      |> Ecto.Changeset.change(%{})
      |> Ecto.Changeset.put_assoc(:source, source)
      |> Comment.changeset(params)

    full_comment =
      UserPermissions.lock!(user, :add_comment, fn _ -> Repo.insert!(comment_changeset) end)
      |> Map.put(:user, user)
      |> Repo.preload(:source)
      |> Map.put(:score, 1)

    # Self vote
    Task.start(fn() -> vote(user, full_comment.id, 1) end)

    # If new source, fetch metadata
    unless is_nil(source) || Map.get(source, :id),
      do: fetch_source_metadata_and_update_comment(full_comment, source_fetch_callback)
    full_comment
  end

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

  # ---- Private ----

  defp fetch_source_metadata_and_update_comment(%Comment{source: nil}, _), do: nil
  defp fetch_source_metadata_and_update_comment(comment = %Comment{source: base_source}, callback) do
    Fetcher.fetch_source_metadata(base_source.url, fn
      metadata when metadata == %{} -> nil
      metadata ->
        og_url = Map.get(metadata, :url)
        updated_source =
          # Check if we got a new url from metadata
          if og_url && og_url != base_source.url do
            case Repo.transaction(fn ->
              # Get real source (or create it)
              real_source = case Repo.get_by(Source, url: og_url) do
                nil -> Repo.insert!(Source.changeset(%Source{}, metadata))
                source -> Repo.update!(Source.changeset(source, metadata))
              end
              # Update all references to prev source
              Comment
              |> where([c], c.source_id == ^base_source.id)
              |> Repo.update_all(set: [source_id: real_source.id])

              # Delete original source
              Repo.delete!(base_source)

              real_source # Return updated source
            end) do
              {:ok, real_source} ->
                real_source
              {:error, _} ->
                Logger.error("Source update for #{base_source.url} with new url #{og_url} failed")
            end
          else
            # Otherwise just update source with new metadata
            Repo.update!(Source.changeset(base_source, metadata))
          end

        # TODO Comment may have been edited. Reload from DB
        if updated_source && callback, do: callback.(Map.put(comment, :source, updated_source))
    end)
  end
end