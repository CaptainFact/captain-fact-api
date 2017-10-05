defmodule CaptainFact.Comments do
  import Ecto.{Query}
  require Logger

  alias CaptainFact.Repo
  alias CaptainFact.Comments.{Comment, Vote}
  alias CaptainFact.Accounts.{UserPermissions, User}
  alias CaptainFact.Sources.{Fetcher, Source}
  alias CaptainFact.Actions.Recorder


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
      UserPermissions.lock!(user, :create, :comment, fn _ -> Repo.insert!(comment_changeset) end)
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

  def vote(user, comment_id, 0),
    do: delete_vote(user, Repo.get!(Comment, comment_id))
  def vote(user, comment_id, value) do
    comment = Repo.get!(Comment, comment_id)
    vote_type = Vote.vote_type(user, comment, value)
    comment_type = comment_type(comment)
    UserPermissions.check!(user, vote_type, comment_type)

    # Delete prev vote if any
    prev_vote = Repo.get_by(Vote, user_id: user.id, comment_id: comment_id)
    if prev_vote, do: delete_vote(user, comment, prev_vote)

    # Record vote
    return =
      Ecto.build_assoc(user, :votes)
      |> Vote.changeset(%{comment_id: comment_id, value: value})
      |> Repo.insert!()
    Recorder.record!(user, vote_type, comment_type, %{target_user_id: comment.user_id})
    return
  end

  def delete_vote(user, comment = %Comment{}),
    do: delete_vote(user, comment, Repo.get_by!(Vote, user_id: user.id, comment_id: comment.id))
  def delete_vote(user = %User{id: user_id}, comment = %Comment{}, vote = %Vote{user_id: user_id}) do
    vote_type = reverse_vote_type(Vote.vote_type(user, comment, vote.value))
    comment_type = comment_type(comment)
    UserPermissions.check!(user, vote_type, comment_type)
    Repo.delete(vote)
    Recorder.record!(user, vote_type, comment_type, %{target_user_id: comment.user_id})
    %Vote{comment_id: comment.id}
  end

  def comment_type(%Comment{source_id: nil}), do: :comment
  def comment_type(%Comment{}), do: :fact

  # ---- Private ----

  defp reverse_vote_type(:vote_up), do: :revert_vote_up
  defp reverse_vote_type(:vote_down), do: :revert_vote_down
  defp reverse_vote_type(:self_vote), do: :revert_self_vote

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