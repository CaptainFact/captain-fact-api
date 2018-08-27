defmodule CF.Utils.FrontendRouter do
  @moduledoc """
  Generate routes matching Frontend URL.
  """

  alias DB.Schema.User

  @doc """
  Base frontend URL

  ## Examples

      iex> CF.Utils.FrontendRouter.base_url()
      "https://TEST_FRONTEND"
  """
  def base_url, do: Application.fetch_env!(:captain_fact, :frontend_url)

  @doc """
  User's profile page URL
  """
  def user_url(%User{username: username}), do: base_url() <> "/#{username}"
end
