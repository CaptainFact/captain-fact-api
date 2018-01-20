defmodule DB.Type.Achievement do
  @doc"""
  Get an achievement id from an easy to use / remember atom. You can add more at the end, but you CANNOT change
  existing identifiers, it would break existing achievements
  """
  def get(:welcome),            do: 1
  def get(:not_a_robot),        do: 2
  def get(:help),               do: 3
  def get(:bulletproof),        do: 4
  def get(:you_are_fake_news),  do: 5
  def get(:social_networks),    do: 6
end
