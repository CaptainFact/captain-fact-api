defmodule DB.Type.Achievement do
  @moduledoc """
  Translate a user achievement from atom to integer.
  TODO: Migrate this to a real Ecto.Type using Ecto.Enum
  """

  @doc """
  Get an achievement id from an easy to use / remember atom.
  You can add more at the end, but you CANNOT change
  existing identifiers, it would break existing achievements
  """
  # Default badge
  def get(:welcome), do: 1
  # Validate email or link third party account
  def get(:not_a_robot), do: 2
  # Visit help pages
  def get(:help), do: 3
  # Install extension
  def get(:bulletproof), do: 4
  # ???
  def get(:you_are_fake_news), do: 5
  # Link third party account
  def get(:social_networks), do: 6
  # Ambassador
  def get(:ambassador), do: 7
  # Made a bug report
  def get(:ghostbuster), do: 8
  # Leaderboard
  def get(:famous), do: 9
  # Made a contribution on the graphics
  def get(:artist), do: 10
  # Made a suggestion that gets approved
  def get(:good_vibes), do: 11
end
