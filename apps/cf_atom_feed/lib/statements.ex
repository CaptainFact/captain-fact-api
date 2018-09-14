defmodule CF.AtomFeed.Statements do
  import Ecto.Query

  alias Atomex.{Feed, Entry}
  alias DB.Schema.Statement
  alias CF.Utils.FrontendRouter

  @nb_items_max 50

  @doc """
  Get an RSS feed containing all site's statements in reverse chronological
  order (newest first)
  """
  def feed_all() do
    statements = fetch_statements()
    generate_feed(statements, last_update(statements))
  end

  def fetch_statements() do
    Statement
    |> join(:inner, [s], v in assoc(s, :video))
    |> join(:left, [s, v], sp in assoc(s, :speaker))
    |> order_by([s, v, sp], desc: [s.id])
    |> select([s, v, sp], %{
      id: s.id,
      time: s.time,
      text: s.text,
      inserted_at: s.inserted_at,
      speaker: %{
        id: sp.id,
        slug: sp.slug,
        full_name: sp.full_name
      },
      video: %{
        hash_id: v.hash_id,
        title: v.title
      }
    })
    |> limit(@nb_items_max)
    |> DB.Repo.all()
  end

  defp last_update(_statements = [statement | _]),
    do: DateTime.from_naive!(statement.inserted_at, "Etc/UTC")

  defp last_update(_),
    do: DateTime.utc_now()

  defp generate_feed(statements, last_update) do
    FrontendRouter.base_url()
    |> Feed.new(last_update, "[CaptainFact] All Statements")
    |> CF.AtomFeed.Common.feed_author()
    |> Feed.link("https://feed.captainfact.io/statements/", rel: "self")
    |> Feed.entries(Enum.map(statements, &get_entry/1))
    |> Feed.build()
    |> Atomex.generate_document()
  end

  defp get_entry(statement) do
    title = "New statement for video #{statement.video.title}"
    insert_datetime = DateTime.from_naive!(statement.inserted_at, "Etc/UTC")
    link_statement = FrontendRouter.statement_url(statement.video.hash_id, statement.id)

    Entry.new(link_statement, insert_datetime, title)
    |> Entry.link(link_statement)
    |> Entry.published(insert_datetime)
    |> Entry.content("""
    At #{timecode_to_time(statement.time)}:
    ```
    #{statement.text}
    ```
    """)
    |> Entry.build()
  end

  defp timecode_to_time(timecode) do
    hours_time_code =
      div(timecode, 3600)
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    minutes_time_code =
      div(rem(timecode, 3600), 60)
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    seconds_time_code =
      rem(rem(timecode, 3600), 60)
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    "#{hours_time_code}:#{minutes_time_code}:#{seconds_time_code}"
  end
end
