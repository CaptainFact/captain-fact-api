defmodule CF.AtomFeed.Comments do
  @moduledoc """
  Generate an ATOM feed that contains all comments
  """

  import Ecto.Query

  alias Atomex.{Feed, Entry}
  alias DB.Schema.{Comment, User}
  alias CF.Utils.FrontendRouter

  @nb_items_max 50

  @doc """
  Get an ATOM feed containing all site's comments in reverse chronological
  order (newest first)
  """
  def feed_all() do
    comments = fetch_comments()
    generate_feed(comments, last_update(comments))
  end

  defp fetch_comments() do
    DB.Repo.all(
      from(
        c in Comment,
        join: statement in assoc(c, :statement),
        left_join: user in assoc(c, :user),
        left_join: source in assoc(c, :source),
        preload: [:statement, :user, :source],
        order_by: [desc: c.inserted_at],
        limit: @nb_items_max
      )
    )
  end

  defp last_update(_comments = [comment | _]),
    do: DateTime.from_naive!(comment.inserted_at, "Etc/UTC")

  defp last_update(_),
    do: DateTime.utc_now()

  defp generate_feed(comments, last_update) do
    Feed.new(FrontendRouter.base_url(), last_update, "[CaptainFact] All Comments")
    |> Feed.author("CaptainFact", email: "atom-feed@captainfact.io")
    |> Feed.link("https://feed.captainfact.io/comments/", rel: "self")
    |> Feed.entries(Enum.map(comments, &get_entry/1))
    |> Feed.build()
    |> Atomex.generate_document()
  end

  defp get_entry(comment) do
    user_appelation = User.user_appelation(comment.user)
    title = entry_title(comment, user_appelation)
    link = comment_url(comment)
    insert_datetime = DateTime.from_naive!(comment.inserted_at, "Etc/UTC")

    link
    |> Entry.new(insert_datetime, title)
    |> Entry.link(link)
    |> Entry.published(insert_datetime)
    |> Entry.author(user_appelation, uri: comment.user && FrontendRouter.user_url(comment.user))
    |> Entry.content("""
    ```
    #{comment.text}
    ```
    Source: #{source(comment)}
    """)
    |> Entry.build()
  end

  defp entry_title(comment, user_appelation) do
    type = if comment.source, do: "Sourced comment", else: "Comment"
    "New #{type} from #{user_appelation} on ##{comment.statement.id}"
  end

  defp source(%{source: nil}),
    do: "None"

  defp source(%{source: %{url: url, site_name: site_name}}),
    do: "[#{site_name || url}](#{url})"

  defp comment_url(comment) do
    video_hash_id = DB.Type.VideoHashId.encode(comment.statement.video_id)
    FrontendRouter.comment_url(video_hash_id, comment)
  end
end
