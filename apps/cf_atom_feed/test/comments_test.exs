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
    assert String.starts_with?(feed, """
           <?xml version="1.0" encoding="UTF-8"?>
           <feed xmlns="http://www.w3.org/2005/Atom">
             <link href="https://feed.captainfact.io/comments/" rel="self"/>
             <author>
               <name>Captain Fact</name>
               <email>atom-feed@captainfact.io</email>
             </author>
             <id>https://captainfact.io/</id>
             <title>[CaptainFact] All Comments</title>
           """)

    # Check comment entries
    for comment <- comments do
      assert feed =~
               ~r(<link href="https://captainfact\.io/videos/[a-zA-Z0-9]+\?statement=#{
                 comment.statement_id
               }"/>)

      assert feed =~
               ~r(<title>New Comment from user ##{comment.user_id} on ##{comment.statement_id}</title>)
    end
  end
end
