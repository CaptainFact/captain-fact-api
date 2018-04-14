defmodule CaptainFactAtomFeed.StatementsTest do
  use ExUnit.Case
  alias DB.{Repo, Schema, Factory}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
  end

  test "render a basic feed" do
    # Ensure comments from previous tests get deleted
    Repo.delete_all(Schema.Statement)

    # Insert fake comments and render feed
    statements = Factory.insert_list(5, :statement)
    feed = CaptainFactAtomFeed.Statements.feed_all()

    # Check feed info
    assert String.starts_with?(feed, """
    <?xml version="1.0" encoding="UTF-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <link href="https://feed.captainfact.io/statements/" rel="self"/>
      <author>
        <name>Captain Fact</name>
        <email>atom-feed@captainfact.io</email>
      </author>
      <id>https://captainfact.io/</id>
      <title>[CaptainFact] All Statements</title>
    """)

    # Check comment entries
    for statement <- statements do
      assert feed =~ ~r(<link href="https://captainfact\.io/videos/[a-zA-Z0-9]+\?statement=#{statement.id}"/>)
      assert feed =~ ~r(<title>New statement on ##{statement.video.id}</title>)
    end
  end
end