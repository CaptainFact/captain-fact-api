defmodule CaptainFact.Accounts.GuardianSerializer do
  @behaviour Guardian.Serializer

  alias CaptainFact.Repo
  alias CaptainFact.Accounts.User
  def for_token(%User{id: id}), do: {:ok, "User:#{id}"}
  def for_token(_), do: {:error, "Unknown resource type"}

  def from_token("User:" <> id), do: {:ok, Repo.get(User, id)}
  def from_token(_), do: {:error, "Unknown resource type"}
end
