defmodule CaptainFactWeb.RSSFeedController do
  use CaptainFactWeb, :controller

  import Ecto.Query
  import HtmlEntities, only: [encode: 1]

  @doc"""
  Get an RSS feed containing all site's comments in reverse chronological order (newest first)
  """
  def all_comments(conn, _) do
    comments = DB.Repo.all from(c in DB.Schema.Comment, order_by: [desc: c.inserted_at], preload: [:source])
    conn
    |> put_resp_content_type("application/rss+xml")
    |> send_resp(200, generate_feed(comments))
  end

  defp generate_feed(comments) do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <rss version="2.0">
    <channel>
      <title>CaptainFact - All comments</title>
      <link>https://captainfact.io</link>
      <description>CaptainFact - All Comments</description>
      <ttl>30</ttl>
      #{Enum.join(generate_items(comments), "")}
    </channel>
    </rss>
    """
  end

  defp generate_items(comments) do
    Enum.map(comments, fn comment ->
      comment_text = if comment.text, do: encode(comment.text), else: "[Fact]"
      """
      <item>
        <title>New comment from user ##{comment.user_id} on ##{comment.statement_id}: #{comment_text}</title>
        <description>
          ID: #{comment.id}
          User: #{comment.user_id}
          Text: #{comment_text}
          Statement: #{comment.statement_id}
          Source: #{source(comment)}
        </description>
      </item>
      """
    end)
  end

  defp source(%{source: nil}), do: "None"
  defp source(%{source: %{url: url, site_name: site_name}}), do: "#{site_name} - #{url}"
end