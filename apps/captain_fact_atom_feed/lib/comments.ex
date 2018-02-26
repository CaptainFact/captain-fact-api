defmodule CaptainFactAtomFeed.Comments do
  import Ecto.Query

  alias Atomex.{Feed, Entry}

  @nb_items_max 50

  @doc"""
  Get an RSS feed containing all site's comments in reverse chronological
  order (newest first)
  """
  def feed_all() do
    comments = fetch_comments()
    generate_feed(comments, last_update(comments))
  end

  defp fetch_comments() do
    DB.Repo.all(
      from(
        c in DB.Schema.Comment,
        join: statement in assoc(c, :statement),
        left_join: source in assoc(c, :source),
        order_by: [desc: c.inserted_at],
        limit: @nb_items_max,
        select: %{
          id: c.id,
          text: c.text,
          user_id: c.user_id,
          inserted_at: c.inserted_at,
          source: %{
            url: source.url,
            site_name: source.site_name
          },
          statement: %{
            id: statement.id,
            video_id: statement.video_id,
          }
        }
      )
    )
  end

  defp last_update(_comments = [comment | _]),
    do: DateTime.from_naive!(comment.inserted_at, "Etc/UTC")
  defp last_update(_),
    do: DateTime.utc_now()

  defp generate_feed(comments, last_update) do
    Feed.new("https://captainfact.io/", last_update, "[CaptainFact] All Comments")
    |> Feed.author("Captain Fact", email: "atom-feed@captainfact.io")
    |> Feed.link("https://feed.captainfact.io/comments/", rel: "self")
    |> Feed.entries(Enum.map(comments, &get_entry/1))
    |> Feed.build()
    |> Atomex.generate_document()
  end

  defp get_entry(comment) do
    type = if comment.source.url, do: "Fact", else: "Comment"
    title = "New #{type} from user ##{comment.user_id} on ##{comment.statement.id}"
    link = comment_url(comment)
    insert_datetime = DateTime.from_naive!(comment.inserted_at, "Etc/UTC")

    Entry.new(link, insert_datetime, title)
    |> Entry.link(link)
    |> Entry.published(insert_datetime)
    |> Entry.content("""
          <div>ID: #{comment.id}</div>
          <div>User: #{comment.user_id}</div>
          <div>Text: #{comment.text}</div>
          <div>Statement: #{comment.statement.id}</div>
          <div>Posted at: #{comment.inserted_at}</div>
          <div>#{source(comment)}</div>
    """, type: "html")
    |> Entry.build()
  end

  defp source(%{source: nil}),
    do: "None"
  defp source(%{source: %{url: url, site_name: site_name}}),
    do: "<a href='#{url}'>[Source] #{site_name}</a>"

  defp comment_url(comment) do
    video_hash_id = DB.Type.VideoHashId.encode(comment.statement.video_id)
    "https://captainfact.io/videos/#{video_hash_id}?statement=#{comment.statement.id}"
  end
end