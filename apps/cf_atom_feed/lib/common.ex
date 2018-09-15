defmodule CF.AtomFeed.Common do
  @moduledoc """
  Common ATOM feed functions
  """

  @doc """
  Default feed author
  """
  def feed_author(feed),
    do: Atomex.Feed.author(feed, "CaptainFact", email: "atom-feed@captainfact.io")

  @doc """
  Feed base URL
  """
  def feed_base_url(),
    do: "https://feed.captainfact.io/"
end
