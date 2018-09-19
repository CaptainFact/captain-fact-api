defmodule CF.Utils.FrontendRouter do
  @moduledoc """
  Generate routes matching Frontend URL.
  """

  alias DB.Type.VideoHashId

  alias DB.Schema.User
  alias DB.Schema.Speaker
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
  Statement's URL
  """
  def statement_url(%{video_id: video_id, id: statement_id}),
    do: statement_url(VideoHashId.encode(video_id), statement_id)

  def statement_url(video_hash_id, statement_id),
    do: video_url(video_hash_id) <> "?statement=#{statement_id}"

  @doc """
  Comment's URL
  """
  def comment_url(video_hash_id, %Comment{statement: statement}),
    do: statement_url(video_hash_id, statement.id)

  @doc """
  Speaker URL
  """
  def speaker_url(%Speaker{slug: slug, id: id}),
    do: base_url() <> "s/#{slug || id}"
end
