defmodule CF.AtomFeed.Statements do
  import Ecto.Query

  alias Atomex.{Feed, Entry}
  alias DB.Schema.Statement

  @nb_items_max 50

  @url "https://www.captainfact.io"

  @doc"""
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
    |> select([s, v, sp], %{id: s.id, time_code: s.time, content: s.text, creation_time: s.inserted_at,
                         speaker_id: sp.id, speaker: sp.full_name,
                         video_id: v.id, video_title: v.title})
    |> limit(50)
    |> DB.Repo.all()
  end

  defp last_update(_statements = [statement| _]),
    do: DateTime.from_naive!(statement.creation_time, "Etc/UTC")
  defp last_update(_),
    do: DateTime.utc_now()

  defp generate_feed(statements, last_update) do
    Feed.new("https://captainfact.io/", last_update, "[CaptainFact] All Statements")
    |> Feed.author("Captain Fact", email: "atom-feed@captainfact.io")
    |> Feed.link("https://feed.captainfact.io/statements/", rel: "self")
    |> Feed.entries(Enum.map(statements, &get_entry/1))
    |> Feed.build()
    |> Atomex.generate_document()
  end

  defp get_entry(statement) do
    title = "New statement on ##{statement.video_id}"
    insert_datetime = DateTime.from_naive!(statement.creation_time, "Etc/UTC")
    link_statement = statement_url(statement)
    link_video = video_url(statement)

    Entry.new(link_statement, insert_datetime, title)
    |> Entry.link(link_statement)
    |> Entry.published(insert_datetime)
    |> Entry.content("""
          <div>ID: #{statement.id}</div>
          <div>Time code: #{timecode_to_time(statement.time_code)}</div>
          <div>Text: #{statement.content}</div>
          <div>Posted at: #{insert_datetime}</div>
          <div>Video title: #{statement.video_title}</div>
      """<> speaker_info(statement) <>
      """
          <div>#{source(link_video, "Video link")}</div>
          <div>#{source(link_statement, "Statement link")}</div>
    """, type: "html")
    |> Entry.build()
  end


  defp timecode_to_time(timecode) do
    hours_time_code = div(timecode, 3600)
                      |> Integer.to_string
                      |> String.pad_leading(2, "0")
    minutes_time_code = div(rem(timecode, 3600), 60)
                        |> Integer.to_string
                        |> String.pad_leading(2, "0")
    seconds_time_code = rem(rem(timecode, 3600), 60)
                        |> Integer.to_string
                        |> String.pad_leading(2, "0")
    "#{hours_time_code}:#{minutes_time_code}:#{seconds_time_code}"
  end

  defp speaker_info(%{speaker_id: nil}), do:
    ""
  defp speaker_info(statement) do
    link_speaker = speaker_url(statement)
    """
    <div>Speaker : #{statement.speaker}</div>
    <div>#{source(link_speaker, "Speaker profile")}</div>
    """
  end

  defp source(url, site_name),
       do: "<a href='#{url}'>[Source] #{site_name}</a>"

  defp statement_url(nil) do
    "#{@url}/"
  end

  defp statement_url(statement) do
    video_hash_id = DB.Type.VideoHashId.encode(statement.video_id)
    "#{@url}/videos/#{video_hash_id}?statement=#{statement.id}"
  end

  defp speaker_url(statement) do
    "#{@url}/s/#{statement.speaker_id}"
  end

  defp video_url(statement) do
    video_hash_id = DB.Type.VideoHashId.encode(statement.video_id)
    "#{@url}/videos/#{video_hash_id}"
  end

end
