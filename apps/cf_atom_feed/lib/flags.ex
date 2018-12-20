defmodule CF.AtomFeed.Flags do
  @moduledoc """
  Generate an ATOM feed that contains all flags
  """

  import Ecto.Query

  alias Atomex.{Feed, Entry}
  alias DB.Schema.{Flag, UserAction, User, Comment}
  alias DB.Type.FlagReason
  alias CF.Utils.FrontendRouter

  @nb_items_max 50

  @doc """
  Get an ATOM feed containing all site's flags in reverse chronological
  order (newest first)
  """
  def feed_all() do
    flags = fetch_flags()
    generate_feed(flags, last_update(flags))
  end

  defp fetch_flags() do
    DB.Repo.all(
      from(
        flag in Flag,
        order_by: [desc: flag.inserted_at],
        left_join: action in assoc(flag, :action),
        left_join: comment in assoc(action, :comment),
        left_join: user in assoc(comment, :user),
        left_join: source in assoc(comment, :source),
        preload: [action: [comment: [:user, :statement, :source]]],
        limit: @nb_items_max
      )
    )
  end

  defp last_update(_flags = [flag | _]),
    do: DateTime.from_naive!(flag.inserted_at, "Etc/UTC")

  defp last_update(_),
    do: DateTime.utc_now()

  defp generate_feed(flags, last_update) do
    FrontendRouter.base_url()
    |> Feed.new(last_update, "[CaptainFact] All Flags")
    |> CF.AtomFeed.Common.feed_author()
    |> Feed.link("https://feed.captainfact.io/flags/", rel: "self")
    |> Feed.entries(Enum.map(flags, &get_entry/1))
    |> Feed.build()
    |> Atomex.generate_document()
  end

  defp get_entry(flag) do
    comment = flag.action.comment
    user_appelation = User.user_appelation(comment.user)
    title = entry_title(flag, user_appelation)
    link = comment_url(flag.action)
    insert_datetime = DateTime.from_naive!(flag.inserted_at, "Etc/UTC")

    link
    |> Entry.new(insert_datetime, title)
    |> Entry.link(link)
    |> Entry.published(insert_datetime)
    |> Entry.content("""
    ```
    #{comment.text}
    ```
    Source Comment: #{source(comment)}\n
    Flag reason: #{FlagReason.label(flag.reason)}
    """)
    |> Entry.build()
  end

  defp source(%{source: nil}),
    do: "None"

  defp source(%{source: %{url: url, site_name: site_name}}),
    do: "[#{site_name || url}](#{url})"

  defp entry_title(flag, user_appelation) do
    "New Flag for #{user_appelation} comment ##{flag.action.comment.id}"
  end

  defp comment_url(action) do
    video_hash_id = DB.Type.VideoHashId.encode(action.video_id)
    FrontendRouter.comment_url(video_hash_id, action.comment)
  end
end
