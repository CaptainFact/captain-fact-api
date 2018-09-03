defmodule CF.Utils.FrontendRouter do
  @moduledoc """
  Generate routes matching Frontend URL.
  """

  alias DB.Schema.User
  alias DB.Schema.Comment

  @doc """
  Base frontend URL

  # TODO LOAD THIS IN CONFIG
  """
  def base_url, do: "https://captainfact.io/"

  @doc """
  User's profile page URL
  """
  def user_url(%User{username: username}), do: base_url() <> "u/#{username}"

  @doc """
  Video URL
  """
  def video_url(video_hash_id), do: base_url() <> "videos/#{video_hash_id}"

  @doc """
  Comment's URL
  """
  def comment_url(video_hash_id, %Comment{statement: statement}),
    do: video_url(video_hash_id) <> "?statement=#{statement.id}"
end
