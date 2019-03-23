defmodule CF.ThirdParty.Youtube do
  @moduledoc """
  Wrapper arround YouTube API
  """

  require Logger

  alias GoogleApi.YouTube.V3.Connection
  alias GoogleApi.YouTube.V3.Api.CommentThreads

  def post_comment(youtube_id, body) do
    if !Application.get_env(:cf, :notify_youtube_for_new_videos) do
      Connection.new()
      |> CommentThreads.youtube_comment_threads_insert("snippet",
        videoId: youtube_id,
        body: body,
        oauth_token:
          "ya29.GlvVBmN_ZnrN8BFYHZRxPS6HbvzYfppV5Mr-fw26O5dIhMZqJmcnMpvO-D-aI3C3wvL0Rzy3kDU1DshsxZOa5T0hjkCERe2UjtYujVvxBwQo410c9bsWbe5y-rm1"
      )
    else
      Logger.debug(
        "YouTube integration not configured. Would have commented the thread with: #{body}"
      )
    end
  end
end
