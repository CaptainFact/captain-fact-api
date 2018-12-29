defmodule CF.Utils.FrontendRouter do
  @moduledoc """
  Generate routes matching Frontend URL.
  """

  alias DB.Schema.User
  alias DB.Schema.Speaker
  alias DB.Schema.Comment

  @doc """
  Base frontend URL
  """
  def base_url, do: Application.get_env(:cf, :frontend_url)

  @doc """
  Build an url for given path
  """
  def url(path \\ "")
  def url("/" <> path), do: base_url() <> path
  def url(path), do: base_url() <> path

  @doc """
  User's profile page URL
  """
  def user_url(%User{username: username}), do: url("u/#{username}")

  @doc """
  Video URL
  """
  def video_url(video_hash_id), do: url("videos/#{video_hash_id}")

  @doc """
  Comment's URL
  """
  def statement_url(video_hash_id, statement_id),
    do: video_url(video_hash_id) <> "?statement=#{statement_id}"

  @doc """
  Comment's URL
  """
  def comment_url(video_hash_id, %Comment{id: id, statement: statement}),
    do: statement_url(video_hash_id, statement.id) <> "&c=#{id}"

  @doc """
  Speaker URL
  """
  def speaker_url(%Speaker{slug: slug, id: id}),
    do: url("s/#{slug || id}")

  @doc """
  URL to unsubscribe from newsletter
  """
  def unsubscribe_newsletter_url(newsletter_subscription_token),
    do: url("newsletter/unsubscribe/#{newsletter_subscription_token}")

  @doc """
  URL to confirm email
  """
  def confirm_email_url(email_confirmation_token),
    do: url("confirm_email/#{email_confirmation_token}")

  @doc """
  URL to reset user password
  """
  def reset_password_url(reset_password_token),
    do: url("reset_password/confirm/#{reset_password_token}")

  @doc """
  URL to help pages
  """
  def help_url(),
    do: url("help")

  @doc """
  Invitation URL
  """
  def invitation_url(token),
    do: url("signup?invitation_token=#{token}")
end
