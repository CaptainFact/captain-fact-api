defmodule CF.AtomFeed.CommentsTest do
  use ExUnit.Case
  alias DB.{Repo, Schema, Factory}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
  end

  test "render a basic feed" do
    # Ensure comments from previous tests get deleted
    Repo.delete_all(Schema.Comment)

    # Insert fake comments and render feed
    comments = Factory.insert_list(5, :comment)
    feed = CF.AtomFeed.Comments.feed_all()

    # Check feed info
    assert feed =~ """
           <?xml version="1.0" encoding="UTF-8"?>
           <feed xmlns="http://www.w3.org/2005/Atom">
             <link href="https://feed.captainfact.io/comments/" rel="self"/>
             <author>
               <name>CaptainFact</name>
               <email>atom-feed@captainfact.io</email>
             </author>
             <id>https://TEST_FRONTEND/</id>
             <title>[CaptainFact] All Comments</title>
           """

    # Check comment entries
    for comment <- comments do
      assert feed =~
               ~r(https://TEST_FRONTEND/videos/[a-zA-Z0-9]+\?statement=#{comment.statement_id}&amp;c=#{
                 comment.id
               }"/>)

      assert feed =~ ~r(<title>New Comment from .+ on ##{comment.statement_id}</title>)
    end
  end

  test "should properly render anonymized comments" do
    # Ensure comments from previous tests get deleted
    Repo.delete_all(Schema.Comment)

    Factory.insert(:comment, user: nil)
    feed = CF.AtomFeed.Comments.feed_all()
    assert feed =~ ~r(New Comment from Deleted account)
  end
end
