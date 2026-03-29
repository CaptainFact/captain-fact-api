defmodule CF.Graphql.Resolvers.Moderation do
  @moduledoc """
  Resolvers for moderation-related queries and mutations
  """

  alias CF.Moderation

  def random(_root, _args, %{context: %{user: user}}) do
    case Moderation.random!(user) do
      nil -> {:ok, nil}
      entry -> {:ok, entry}
    end
  end

  def moderate_action(_root, %{action_id: action_id_str, reason: reason, value: value}, %{
        context: %{user: user}
      }) do
    try do
      action_id = String.to_integer(action_id_str)

      case Moderation.feedback!(user, action_id, value, reason) do
        {:ok, _feedback} ->
          {:ok, %{id: action_id_str}}

        {:error, changeset} ->
          {:error, message: "Failed to submit moderation feedback", details: changeset}
      end
    rescue
      e ->
        {:error, message: "Failed to submit moderation feedback"}
    end
  end
end
